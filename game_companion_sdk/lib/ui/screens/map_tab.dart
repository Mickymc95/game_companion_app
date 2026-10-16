import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../games/gtav/fixtures.dart';
import '../../sdk/map/coords_helper.dart';
import '../../sdk/map/game_map.dart';
import '../../sdk/models/map_poi.dart';
import '../../sdk/models/wiki_item.dart';
import '../../sdk/storage/collection_tracker.dart';
import '../providers/map_providers.dart';
import '../providers/wiki_providers.dart';
import '../../sdk/map/target_map_position_provider.dart';

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = ref.read(targetMapPositionProvider);
      if (target != null) {
        _mapController.move(target.position, target.zoom);
        ref.read(targetMapPositionProvider.notifier).state = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TargetMapPosition?>(targetMapPositionProvider, (previous, next) {
      if (next != null) {
        _mapController.move(next.position, next.zoom);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(targetMapPositionProvider.notifier).state = null;
        });
      }
    });

    final collectedState = ref.watch(collectionTrackerProvider);
    final filterState = ref.watch(mapFilterProvider);
    final poiAsyncValue = ref.watch(mapPoiProvider);
    final activeLayer = ref.watch(activeMapLayerProvider);
    final hideCollected = ref.watch(hideCollectedPinsProvider);
    final highlightedPoi = ref.watch(highlightedPoiProvider);
    final completionSummary = ref.watch(mapCompletionSummaryProvider);

    return Scaffold(
      body: poiAsyncValue.when(
        data: (pois) {
          final filteredPois = pois.where((poi) {
            if (!filterState.contains(poi.category)) return false;
            if (hideCollected && collectedState.contains(poi.id)) return false;
            return true;
          }).toList();

          final markers = filteredPois.map((poi) {
            final isCollected = collectedState.contains(poi.id);
            final isHighlighted = highlightedPoi?.id == poi.id;

            Color iconColor;
            IconData iconData;

            if (poi.category == 'collectibles') {
              iconColor = Colors.greenAccent;
              iconData = Icons.rocket_launch;
            } else if (poi.category == 'stunts') {
              iconColor = Colors.deepOrange;
              iconData = Icons.sports_motorsports;
            } else if (poi.category == 'services') {
              iconColor = Colors.redAccent;
              iconData = Icons.shield;
            } else {
              iconColor = Colors.blueAccent;
              iconData = Icons.location_on;
            }

            return Marker(
              point: inGameToMapCoords(poi.gameX, poi.gameY),
              width: isHighlighted ? 48 : 40,
              height: isHighlighted ? 48 : 40,
              child: GestureDetector(
                onTap: () {
                  _showPoiDetails(context, ref, poi);
                },
                child: Opacity(
                  opacity: isCollected ? 0.35 : 1.0,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: isHighlighted ? Colors.amber : iconColor,
                          shape: BoxShape.circle,
                          boxShadow: isHighlighted
                              ? [
                                  BoxShadow(
                                    color: Colors.amber.withValues(alpha: 0.8),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                          border: isHighlighted
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                        ),
                        child: Center(
                          child: Icon(
                            isHighlighted ? Icons.my_location : iconData,
                            color: Colors.white,
                            size: isHighlighted ? 24 : 22,
                          ),
                        ),
                      ),
                      if (isCollected)
                        Container(
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList();

          return Stack(
            children: [
              GameMap(
                mapController: _mapController,
                tileUrlTemplate: activeLayer.urlTemplate,
                backgroundColor: activeLayer.backgroundColor,
                fallbackAsset: GTAVFixtures.fallbackMapAsset,
                markers: markers,
                bounds: kGtaMapPanBounds,
                initialCenter: kGtaMapCenter,
              ),

              // Top Controls Header: Filters & Telemetry Summary
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 0,
                right: 0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // Completion Telemetry Pill
                          ActionChip(
                            avatar: const Icon(Icons.check_circle_outline, size: 18),
                            label: Text(
                              '${completionSummary.collectedCount}/${completionSummary.totalCount} Found (${(completionSummary.percentage * 100).toInt()}%)',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            onPressed: () => _showCompletionSummarySheet(context, ref, completionSummary),
                          ),
                          const SizedBox(width: 8),

                          // Quick Toggle: Hide / Show Found
                          FilterChip(
                            avatar: Icon(
                              hideCollected ? Icons.visibility_off : Icons.visibility,
                              size: 16,
                            ),
                            label: const Text('Hide Found'),
                            selected: hideCollected,
                            onSelected: (val) {
                              ref.read(hideCollectedPinsProvider.notifier).state = val;
                            },
                          ),
                          const SizedBox(width: 8),

                          _buildFilterChip(
                              ref, filterState, 'All', ['collectibles', 'stunts', 'services']),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              ref, filterState, 'Collectibles', ['collectibles']),
                          const SizedBox(width: 8),
                          _buildFilterChip(ref, filterState, 'Stunts', ['stunts']),
                          const SizedBox(width: 8),
                          _buildFilterChip(ref, filterState, 'Services', ['services']),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom-Left Floating Layer Switcher
              Positioned(
                bottom: 16,
                left: 16,
                child: FloatingActionButton.small(
                  heroTag: 'map_layer_switcher',
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  tooltip: 'Switch Map Layer',
                  child: Icon(activeLayer.icon),
                  onPressed: () => _showLayerSwitcherSheet(context, ref),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'map_category_filter',
        child: const Icon(Icons.filter_list),
        onPressed: () {
          _showFilterSheet(context, ref);
        },
      ),
    );
  }

  Widget _buildFilterChip(
      WidgetRef ref, Set<String> filterState, String label, List<String> categories) {
    final isSelected = categories.every((cat) => filterState.contains(cat));
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        final notifier = ref.read(mapFilterProvider.notifier);
        if (label == 'All') {
          if (selected) {
            for (var cat in categories) {
              if (!filterState.contains(cat)) notifier.toggleCategory(cat);
            }
          } else {
            for (var cat in categories) {
              if (filterState.contains(cat)) notifier.toggleCategory(cat);
            }
          }
        } else {
          notifier.toggleCategory(categories.first);
        }
      },
    );
  }

  void _showLayerSwitcherSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final activeLayer = ref.watch(activeMapLayerProvider);
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Map Style', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  ...MapLayerType.values.map((layer) {
                    final isSelected = layer == activeLayer;
                    return ListTile(
                      leading: Icon(layer.icon, color: isSelected ? Theme.of(context).colorScheme.primary : null),
                      title: Text(layer.displayName, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary) : null,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      selected: isSelected,
                      onTap: () {
                        ref.read(activeMapLayerProvider.notifier).state = layer;
                        Navigator.pop(ctx);
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCompletionSummarySheet(BuildContext context, WidgetRef ref, MapCompletionSummary summary) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final hideCollected = ref.watch(hideCollectedPinsProvider);

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress & Checklist', style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        '${(summary.percentage * 100).toInt()}%',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: summary.percentage,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${summary.collectedCount} of ${summary.totalCount} items collected',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const Divider(height: 32),
                  ...summary.categoryStats.map((cat) {
                    final label = cat.category[0].toUpperCase() + cat.category.substring(1);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text('${cat.collectedCount}/${cat.totalCount} (${(cat.percentage * 100).toInt()}%)'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: cat.percentage,
                            minHeight: 6,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    title: const Text('Hide Collected Pins from Map'),
                    value: hideCollected,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      ref.read(hideCollectedPinsProvider.notifier).state = val;
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final filterState = ref.watch(mapFilterProvider);
            final categories = ['collectibles', 'stunts', 'services'];

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter Map Categories',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: categories.map((cat) {
                      return FilterChip(
                        label: Text(cat),
                        selected: filterState.contains(cat),
                        onSelected: (bool value) {
                          ref
                              .read(mapFilterProvider.notifier)
                              .toggleCategory(cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Apply'),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPoiDetails(BuildContext context, WidgetRef ref, MapPointOfInterest poi) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final isCollected =
                ref.watch(collectionTrackerProvider).contains(poi.id);

            // Attempt to find a matching WikiItem
            final wikiItemsAsync = ref.watch(wikiItemsProvider);
            final allWikiItems = wikiItemsAsync.valueOrNull ?? [];

            final matchingWiki = allWikiItems.cast<WikiItem?>().firstWhere(
              (wiki) => wiki != null && (
                wiki.title.trim().toLowerCase() == poi.name.trim().toLowerCase() ||
                wiki.id.trim().toLowerCase() == poi.id.trim().toLowerCase()
              ),
              orElse: () => null,
            );

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poi.name,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Coordinates: ${poi.gameX}, ${poi.gameY}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(poi.description),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: Icon(isCollected ? Icons.undo : Icons.check),
                      label: Text(isCollected
                          ? 'Mark as Uncollected'
                          : 'Mark as Collected'),
                      onPressed: () {
                        ref
                            .read(collectionTrackerProvider.notifier)
                            .toggleCollection(poi.id);
                        Navigator.pop(ctx);
                      },
                    ),
                  ),

                  // Route Sequencer: Find Next Closest Uncollected POI
                  if (poi.isCollectable) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.near_me),
                        label: const Text('Find Next Closest'),
                        onPressed: () {
                          final allPois = ref.read(mapPoiProvider).valueOrNull ?? [];
                          final collected = ref.read(collectionTrackerProvider);

                          // Prefer uncollected POIs in the same category first
                          final sameCategory = allPois.where(
                            (p) => p.isCollectable && !collected.contains(p.id) && p.id != poi.id && p.category == poi.category,
                          );
                          final candidates = sameCategory.isNotEmpty
                              ? sameCategory
                              : allPois.where((p) => p.isCollectable && !collected.contains(p.id) && p.id != poi.id);

                          final nearest = findNearestPoi(poi, candidates);
                          Navigator.pop(ctx);

                          if (nearest != null) {
                            final dist = distanceBetweenInGameCoords(
                              poi.gameX,
                              poi.gameY,
                              nearest.gameX,
                              nearest.gameY,
                            );
                            ref.read(highlightedPoiProvider.notifier).state = nearest;
                            final target = inGameToMapCoords(nearest.gameX, nearest.gameY);
                            _mapController.move(target, 4.5);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Targeted closest ${nearest.name} (~${dist.toInt()}m away)'),
                                duration: const Duration(seconds: 4),
                                action: SnackBarAction(
                                  label: 'View',
                                  onPressed: () => _showPoiDetails(context, ref, nearest),
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('All collectables in this category are completed!')),
                            );
                          }
                        },
                      ),
                    ),
                  ],

                  if (matchingWiki != null) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.library_books),
                        label: const Text('Wiki / Lore'),
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.push('/wiki/detail', extra: matchingWiki);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
