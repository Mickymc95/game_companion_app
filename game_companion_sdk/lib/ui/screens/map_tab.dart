import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../sdk/map/game_map.dart';
import '../../games/gtav/fixtures.dart';
import '../../sdk/storage/collection_tracker.dart';
import '../providers/map_providers.dart';

class MapTab extends ConsumerWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final poisAsync = ref.watch(mapPoiProvider);
    final isRoadLayer = ref.watch(isRoadLayerProvider);
    final collectedState = ref.watch(collectionTrackerProvider);
    final activeFilters = ref.watch(mapFilterProvider);
    final categories = ref.watch(mapCategoriesProvider);

    // Initialize filters when categories are loaded
    if (categories.isNotEmpty) {
      Future.microtask(() => ref.read(mapFilterProvider.notifier).initializeCategories(categories));
    }

    final tileUrl = isRoadLayer
        ? 'https://gta5-map.github.io/tiles/road/{z}-{x}_{y}.png'
        : 'https://gta5-map.github.io/tiles/satellite/{z}-{x}_{y}.png';

    return Scaffold(
      body: poisAsync.when(
        data: (pois) {
          final filteredPois = pois.where((poi) => activeFilters.contains(poi.category)).toList();

          final markers = filteredPois.map((poi) {
            final isCollected = collectedState.contains(poi.id);
            return Marker(
              point: LatLng(poi.y, poi.x), // CRS.simple maps standard x/y to lat/lng
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  _showPoiDetails(context, ref, poi);
                },
                child: Opacity(
                  opacity: isCollected ? 0.5 : 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCollected ? Icons.check : Icons.location_on,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            );
          }).toList();

          return GameMap(
            tileUrlTemplate: tileUrl,
            fallbackAsset: GTAVFixtures.fallbackMapAsset,
            markers: markers,
            bounds: LatLngBounds(const LatLng(-100, -100), const LatLng(100, 100)), // Dummy bounds for CRS.simple
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading map data: $err')),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'map_layer_toggle',
            child: Icon(isRoadLayer ? Icons.satellite : Icons.map),
            onPressed: () {
              ref.read(isRoadLayerProvider.notifier).state = !isRoadLayer;
            },
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'map_filter_toggle',
            child: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterSheet(context, ref);
            },
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, WidgetRef parentRef) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final categories = ref.watch(mapCategoriesProvider);
            final activeFilters = ref.watch(mapFilterProvider);
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Filter Map Categories', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: categories.map((cat) {
                      return FilterChip(
                        label: Text(cat),
                        selected: activeFilters.contains(cat),
                        onSelected: (bool value) {
                          ref.read(mapFilterProvider.notifier).toggleCategory(cat);
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
          }
        );
      }
    );
  }

  void _showPoiDetails(BuildContext context, WidgetRef ref, dynamic poi) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (context, ref, child) {
            final isCollected = ref.watch(collectionTrackerProvider).contains(poi.id);
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(poi.title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(poi.description),
                  const SizedBox(height: 24),
                  if (poi.isCollectable)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        icon: Icon(isCollected ? Icons.undo : Icons.check),
                        label: Text(isCollected ? 'Mark as Uncollected' : 'Mark as Collected'),
                        onPressed: () {
                          ref.read(collectionTrackerProvider.notifier).toggleCollection(poi.id);
                          Navigator.pop(ctx);
                        },
                      ),
                    )
                ],
              ),
            );
          }
        );
      },
    );
  }
}
