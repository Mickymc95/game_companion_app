import 'dart:math' as math;
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
import '../utils/poi_style_helper.dart';

class MapTab extends ConsumerStatefulWidget {
  const MapTab({super.key});

  @override
  ConsumerState<MapTab> createState() => _MapTabState();
}

class _MapTabState extends ConsumerState<MapTab> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  late final AnimationController _shakeController;
  String? _shakingPoiId;
  int _shakeSequence = 0;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = ref.read(targetMapPositionProvider);
      if (target != null) {
        _handleTargetMapPosition(target);
      }
    });
  }

  @override
  void dispose() {
    _shakeSequence++;
    if (_shakeController.isAnimating) {
      _shakeController.stop();
    }
    _shakeController.dispose();
    super.dispose();
  }

  bool _isMapTabActive() {
    if (!mounted) return false;
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null && !modalRoute.isCurrent) return false;
    if (!TickerMode.of(context)) return false;
    try {
      final loc = GoRouterState.of(context).matchedLocation;
      if (loc.isNotEmpty && loc != '/map') return false;
    } catch (_) {
      // In isolated test environments where GoRouter is not injected
    }
    return true;
  }

  void _cancelShake() {
    _shakeSequence++;
    if (_shakeController.isAnimating) {
      _shakeController.stop();
    }
    _shakeController.reset();
    if (_shakingPoiId != null && mounted) {
      setState(() {
        _shakingPoiId = null;
      });
    }
  }

  void _handleTargetMapPosition(TargetMapPosition target) {
    _mapController.move(target.position, target.zoom);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(targetMapPositionProvider) != null) {
        ref.read(targetMapPositionProvider.notifier).state = null;
      }
    });

    if (target.poiId != null && target.shakeAndOpenCard) {
      _triggerMarkerShakeAndInfoCard(target.poiId!);
    }
  }

  Future<void> _triggerMarkerShakeAndInfoCard(String poiId) async {
    final int currentSequence = ++_shakeSequence;
    if (_shakeController.isAnimating) {
      _shakeController.stop();
    }
    _shakeController.reset();

    List<MapPointOfInterest> pois = ref.read(mapPoiProvider).valueOrNull ?? [];
    if (pois.isEmpty) {
      try {
        pois = await ref.read(mapPoiProvider.future);
      } catch (_) {}
    }

    if (!mounted || _shakeSequence != currentSequence) return;

    // If arriving from another screen (such as /search), wait until the map screen
    // is active and rendered so the user sees the shake animation on arrival.
    int retries = 0;
    while (mounted && _shakeSequence == currentSequence && !_isMapTabActive() && retries < 15) {
      await Future<void>.delayed(const Duration(milliseconds: 30));
      retries++;
    }

    if (!mounted || _shakeSequence != currentSequence || !_isMapTabActive()) return;

    final targetPoi = pois.cast<MapPointOfInterest?>().firstWhere(
      (p) => p?.id == poiId,
      orElse: () => null,
    );

    if (targetPoi == null) return;

    ref.read(mapFilterProvider.notifier).enableSubcategory(targetPoi.subCategory);
    // Keep original map item icon instead of changing it to target symbol (Icons.my_location)
    if (ref.read(highlightedPoiProvider) != null) {
      ref.read(highlightedPoiProvider.notifier).state = null;
    }

    setState(() {
      _shakingPoiId = targetPoi.id;
    });

    try {
      await _shakeController.forward(from: 0.0);
    } catch (_) {}

    // Only proceed if this shake animation completed naturally without being cancelled,
    // superseded by another target, or interrupted by user interaction or screen departure.
    if (!mounted || _shakeSequence != currentSequence) {
      return;
    }

    if (_shakeController.status != AnimationStatus.completed || !_isMapTabActive()) {
      if (_shakingPoiId != null && mounted) {
        setState(() {
          _shakingPoiId = null;
        });
      }
      return;
    }

    if (_shakingPoiId != null && mounted) {
      setState(() {
        _shakingPoiId = null;
      });
    }

    _showPoiDetails(context, ref, targetPoi);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TargetMapPosition?>(targetMapPositionProvider, (previous, next) {
      if (next != null) {
        _handleTargetMapPosition(next);
      }
    });

    if (_shakingPoiId != null && !_isMapTabActive()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _shakingPoiId != null && !_isMapTabActive()) {
          _cancelShake();
        }
      });
    }

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
            final isCollected = collectedState.contains(poi.id);
            final isTargeted = _shakingPoiId == poi.id || highlightedPoi?.id == poi.id;
            return isTargeted || (filterState.isSubcategoryEnabled(poi.subCategory) &&
                (!hideCollected || !isCollected));
          }).toList();

          final markers = filteredPois.map((poi) {
            final isCollected = collectedState.contains(poi.id);
            final isHighlighted = highlightedPoi?.id == poi.id;
            final isShaking = _shakingPoiId == poi.id;
            final style = getPoiStyle(poi);

            final markerColor = isHighlighted ? Colors.amber : style.color;
            final markerIcon = isHighlighted ? Icons.my_location : style.icon;
            final markerSize = isHighlighted ? 48.0 : 40.0;

            return Marker(
              point: inGameToMapCoords(poi.gameX, poi.gameY),
              width: markerSize,
              height: markerSize,
              child: GestureDetector(
                key: Key('map_marker_${poi.id}'),
                onTap: () {
                  _cancelShake();
                  _showPoiDetails(context, ref, poi);
                },
                child: Opacity(
                  opacity: isCollected ? 0.35 : 1.0,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: markerColor,
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
                          child: isShaking
                              ? _ShakingMarkerIcon(
                                  key: Key('shaking_marker_icon_${poi.id}'),
                                  icon: markerIcon,
                                  color: Colors.white,
                                  size: isHighlighted ? 24 : 22,
                                  animation: _shakeController,
                                )
                              : Icon(
                                  markerIcon,
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
                          padding: const EdgeInsets.all(2),
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
                            onPressed: () {
                              _cancelShake();
                              _showCompletionSummarySheet(
                                  context, ref, completionSummary);
                            },
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
                              ref,
                              filterState,
                              'All',
                              const ['collectibles', 'stunts', 'services', 'secrets_world']),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              ref, filterState, 'Collectibles', const ['collectibles']),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              ref, filterState, 'Stunts', const ['stunts']),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              ref, filterState, 'Services', const ['services']),
                          const SizedBox(width: 8),
                          _buildFilterChip(
                              ref, filterState, 'Secrets & World', const ['secrets_world']),
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
                  onPressed: () {
                    _cancelShake();
                    _showLayerSwitcherSheet(context, ref);
                  },
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
          _cancelShake();
          _showFilterSheet(context, ref);
        },
      ),
    );
  }

  Widget _buildFilterChip(
      WidgetRef ref, MapFilterState filterState, String label, List<String> categories) {
    final notifier = ref.read(mapFilterProvider.notifier);
    final bool isSelected;
    if (label == 'All') {
      isSelected = categories.every((cat) => filterState.isCategoryFullyEnabled(cat));
    } else {
      isSelected = filterState.isCategoryFullyEnabled(categories.first);
    }

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        if (label == 'All') {
          if (selected) {
            notifier.enableAll();
          } else {
            notifier.disableAll();
          }
        } else {
          notifier.toggleCategoryGroup(categories.first);
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
                      leading: Icon(layer.icon,
                          color: isSelected ? Theme.of(context).colorScheme.primary : null),
                      title: Text(layer.displayName,
                          style: TextStyle(
                              fontWeight:
                                  isSelected ? FontWeight.bold : FontWeight.normal)),
                      trailing: isSelected
                          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                          : null,
                      shape:
                          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _showCompletionSummarySheet(
      BuildContext context, WidgetRef ref, MapCompletionSummary summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final hideCollected = ref.watch(hideCollectedPinsProvider);

            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.4,
              expand: false,
              builder: (context, scrollController) {
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Progress & Checklist',
                            style: Theme.of(context).textTheme.titleLarge),
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
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(cat.displayName,
                                    style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text(
                                    '${cat.collectedCount}/${cat.totalCount} (${(cat.percentage * 100).toInt()}%)'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: cat.percentage,
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            if (cat.subcategoryStats.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ...cat.subcategoryStats.map((subcat) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 3, horizontal: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        subcat.displayName,
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      Text(
                                        subcat.isCollectable
                                            ? '${subcat.collectedCount}/${subcat.totalCount} (${subcat.remainingCount} left)'
                                            : '${subcat.totalCount} POIs',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
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
                );
              },
            );
          },
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'collectibles':
        return Icons.rocket_launch;
      case 'stunts':
        return Icons.sports_motorsports;
      case 'services':
        return Icons.apartment;
      case 'secrets_world':
        return Icons.auto_awesome;
      default:
        return Icons.category;
    }
  }

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final filterState = ref.watch(mapFilterProvider);
            final filterNotifier = ref.read(mapFilterProvider.notifier);
            final hideCollected = ref.watch(hideCollectedPinsProvider);
            final completionSummary = ref.watch(mapCompletionSummaryProvider);

            const canonicalGroups = [
              'collectibles',
              'stunts',
              'services',
              'secrets_world',
            ];

            return DraggableScrollableSheet(
              initialChildSize: 0.85,
              maxChildSize: 0.95,
              minChildSize: 0.5,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Header with Title and Close
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Map Filters & Progress',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Quick Actions: Select All, Clear All
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text('Select All'),
                            onPressed: () {
                              filterNotifier.enableAll();
                            },
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.deselect, size: 16),
                            label: const Text('Clear All'),
                            onPressed: () {
                              filterNotifier.disableAll();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Global Hide Collected Switch
                      SwitchListTile(
                        title: const Text('Hide Collected Pins'),
                        subtitle: const Text('Dim or hide completed collectibles'),
                        value: hideCollected,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) {
                          ref.read(hideCollectedPinsProvider.notifier).state = val;
                        },
                      ),
                      const Divider(height: 20),

                      // Collapsible accordion groups (ExpansionTile) for the 4 main categories
                      ...canonicalGroups.map((catKey) {
                        final catStats = completionSummary.categoryStats.firstWhere(
                          (c) => c.category == catKey,
                          orElse: () => CategoryCompletionStats(
                            category: catKey,
                            displayName: getCategoryDisplayName(catKey),
                            totalCount: 0,
                            collectedCount: 0,
                            subcategoryStats: [],
                          ),
                        );

                        final isFullyEnabled = filterState.isCategoryFullyEnabled(catKey);
                        final isPartiallyEnabled = filterState.isCategoryPartiallyEnabled(catKey);

                        // Use existing subcategory stats if available, or fallback to schema definitions
                        final subcategories = catStats.subcategoryStats.isNotEmpty
                            ? catStats.subcategoryStats
                            : MapFilterState.getSubcategoriesForCategory(catKey).map((subKey) {
                                return SubcategoryCompletionStats(
                                  subCategory: subKey,
                                  displayName: getSubcategoryDisplayName(subKey),
                                  totalCount: 0,
                                  collectedCount: 0,
                                  isCollectable: true,
                                );
                              }).toList();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: ExpansionTile(
                            key: PageStorageKey<String>('group_$catKey'),
                            initiallyExpanded: true,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getCategoryIcon(catKey),
                                color: Theme.of(context).colorScheme.primary,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              catStats.displayName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4, bottom: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        catStats.totalCount > 0
                                            ? '${catStats.collectedCount}/${catStats.totalCount} completed'
                                            : '${subcategories.length} subcategories',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      if (catStats.totalCount > 0)
                                        Text(
                                          '${(catStats.percentage * 100).toInt()}%',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: catStats.percentage,
                                    minHeight: 4,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                              ),
                            ),
                            trailing: Tooltip(
                              message: isFullyEnabled
                                  ? 'Disable all in ${catStats.displayName}'
                                  : 'Enable all in ${catStats.displayName}',
                              child: Switch(
                                value: isFullyEnabled || isPartiallyEnabled,
                                onChanged: (val) {
                                  filterNotifier.toggleCategoryGroup(catKey);
                                },
                              ),
                            ),
                            children: subcategories.map((subcat) {
                              final style = getPoiStyleForSubcategory(subcat.subCategory);
                              final isEnabled =
                                  filterState.isSubcategoryEnabled(subcat.subCategory);

                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border(
                                    top: BorderSide(
                                      color: Theme.of(context)
                                          .dividerColor
                                          .withValues(alpha: 0.15),
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: style.color.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(style.icon,
                                              color: style.color, size: 18),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                subcat.displayName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 14),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                subcat.isCollectable
                                                    ? '${subcat.collectedCount}/${subcat.totalCount} collected (${subcat.remainingCount} left)'
                                                    : '${subcat.totalCount} locations available',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: isEnabled,
                                          onChanged: (val) {
                                            filterNotifier
                                                .toggleSubcategory(subcat.subCategory);
                                          },
                                        ),
                                      ],
                                    ),
                                    if (subcat.isCollectable && subcat.totalCount > 0) ...[
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: subcat.percentage,
                                          minHeight: 4,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                              style.color),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),

                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  void _showPoiDetails(BuildContext context, WidgetRef ref, MapPointOfInterest poi) {
    final hostContext = mounted ? this.context : context;
    final hostRef = this.ref;

    showModalBottomSheet(
      context: hostContext,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final isCollected =
                ref.watch(collectionTrackerProvider).contains(poi.id);

            // Attempt to find a matching WikiItem
            final wikiItemsAsync = ref.watch(wikiItemsProvider);
            final allWikiItems = wikiItemsAsync.valueOrNull ?? [];

            final matchingWiki = allWikiItems.cast<WikiItem?>().firstWhere(
              (wiki) =>
                  wiki != null &&
                  (wiki.title.trim().toLowerCase() == poi.name.trim().toLowerCase() ||
                      wiki.id.trim().toLowerCase() == poi.id.trim().toLowerCase()),
              orElse: () => null,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: getPoiStyle(poi).color.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getPoiStyle(poi).icon,
                          color: getPoiStyle(poi).color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(poi.name,
                                style: Theme.of(context).textTheme.headlineSmall),
                            Text(
                              '${getCategoryDisplayName(poi.category)} • ${getSubcategoryDisplayName(poi.subCategory)}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Coordinates: ${poi.gameX}, ${poi.gameY}',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Text(poi.description),

                  // Stunt Jump Specifications: Prominently displayed
                  if (poi.subCategory == 'stunt_jumps' ||
                      poi.takeoffDirection != null ||
                      poi.landingZone != null ||
                      poi.vehicleRecommendation != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.deepOrange.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.sports_motorsports,
                                  color: Colors.deepOrange, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Stunt Jump Specifications',
                                style:
                                    Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepOrange,
                                        ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (poi.takeoffDirection != null &&
                              poi.takeoffDirection!.isNotEmpty)
                            _buildSpecRow(context, Icons.north_east,
                                'Takeoff Direction', poi.takeoffDirection!),
                          if (poi.landingZone != null && poi.landingZone!.isNotEmpty)
                            _buildSpecRow(context, Icons.flag_outlined,
                                'Landing Zone', poi.landingZone!),
                          if (poi.vehicleRecommendation != null &&
                              poi.vehicleRecommendation!.isNotEmpty)
                            _buildSpecRow(
                                context,
                                Icons.directions_car_outlined,
                                'Recommended Vehicle',
                                poi.vehicleRecommendation!),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                  if (poi.isCollectable)
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
                            (p) =>
                                p.isCollectable &&
                                !collected.contains(p.id) &&
                                p.id != poi.id &&
                                p.category == poi.category,
                          );
                          final candidates = sameCategory.isNotEmpty
                              ? sameCategory
                              : allPois.where((p) =>
                                  p.isCollectable &&
                                  !collected.contains(p.id) &&
                                  p.id != poi.id);

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
                            final target =
                                inGameToMapCoords(nearest.gameX, nearest.gameY);
                            _mapController.move(target, 4.5);

                            final messenger = ScaffoldMessenger.of(hostContext);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFF2A2831),
                                content: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: getPoiStyle(nearest).color.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        getPoiStyle(nearest).icon,
                                        color: getPoiStyle(nearest).color,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            nearest.name,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Targeted closest (~${dist.toInt()}m away)',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.8),
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 4),
                                action: SnackBarAction(
                                  label: 'View',
                                  textColor: const Color(0xFFD0BCFF),
                                  onPressed: () {
                                    _cancelShake();
                                    messenger.hideCurrentSnackBar();
                                    if (mounted) {
                                      _mapController.move(target, 4.5);
                                      _showPoiDetails(hostContext, hostRef, nearest);
                                    }
                                  },
                                ),
                              ),
                            );
                          } else {
                            final messenger = ScaffoldMessenger.of(hostContext);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: const Color(0xFF2A2831),
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'All collectables in this category are completed!',
                                        style: TextStyle(color: Colors.white, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                duration: const Duration(seconds: 3),
                              ),
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
                          hostContext.push('/wiki/detail', extra: matchingWiki);
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

  Widget _buildSpecRow(
      BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShakingMarkerIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final Animation<double> animation;

  const _ShakingMarkerIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.size,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final progress = animation.value;
        // ~5 full oscillation cycles over ~1000ms duration
        final double wobble = math.sin(progress * 10 * math.pi);
        // Slightly damp over time so it rests cleanly at completion
        final double damping = (1.0 - progress * 0.4);
        final double dx = wobble * 6.0 * damping;
        final double rotation = wobble * 0.18 * damping;

        return Transform(
          transform: Matrix4.translationValues(dx, 0.0, 0.0)..rotateZ(rotation),
          alignment: Alignment.center,
          child: child,
        );
      },
      child: Icon(
        icon,
        color: color,
        size: size,
      ),
    );
  }
}
