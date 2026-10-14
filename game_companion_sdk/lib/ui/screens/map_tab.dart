import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../sdk/map/game_map.dart';
import '../../sdk/map/coords_helper.dart';
import '../../sdk/map/poi_provider.dart';
import '../../games/gtav/fixtures.dart';
import '../../sdk/storage/collection_tracker.dart';
import '../providers/map_filter_provider.dart';
import '../../sdk/models/map_poi.dart';

class MapTab extends ConsumerWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectedState = ref.watch(collectionTrackerProvider);
    final filterState = ref.watch(mapFilterProvider);
    final poiAsyncValue = ref.watch(poiProvider);

    return Scaffold(
      body: poiAsyncValue.when(
        data: (pois) {
          final filteredPois = pois.where((poi) => filterState.contains(poi.category)).toList();
          final markers = filteredPois.map((poi) {
            final isCollected = collectedState.contains(poi.id);

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
              width: 40,
              height: 40,
              child: GestureDetector(
                onTap: () {
                  _showPoiDetails(context, ref, poi);
                },
                child: Opacity(
                  opacity: isCollected ? 0.4 : 1.0,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: iconColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          iconData,
                          color: Colors.white,
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
                            size: 12,
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
                tileUrlTemplate: 'https://gta5-map.github.io/tiles/road/{z}-{x}_{y}.png',
                fallbackAsset: GTAVFixtures.fallbackMapAsset,
                markers: markers,
                // Workaround latlong bounds limits using unsafe values inside simple CRS
                bounds: LatLngBounds(const LatLng(-90.0, -180.0), const LatLng(90.0, 180.0)),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 0,
                right: 0,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(ref, filterState, 'All', ['collectibles', 'stunts', 'services']),
                      const SizedBox(width: 8),
                      _buildFilterChip(ref, filterState, 'Collectibles', ['collectibles']),
                      const SizedBox(width: 8),
                      _buildFilterChip(ref, filterState, 'Stunts', ['stunts']),
                      const SizedBox(width: 8),
                      _buildFilterChip(ref, filterState, 'Services', ['services']),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.filter_list),
        onPressed: () {
          _showFilterSheet(context, ref);
        },
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, Set<String> filterState, String label, List<String> categories) {
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
                   Text('Filter Map Categories', style: Theme.of(context).textTheme.titleLarge),
                   const SizedBox(height: 16),
                   Wrap(
                     spacing: 8,
                     children: categories.map((cat) {
                       return FilterChip(
                         label: Text(cat),
                         selected: filterState.contains(cat),
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

  void _showPoiDetails(BuildContext context, WidgetRef ref, MapPointOfInterest poi) {
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
                  Text(poi.name, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text('Coordinates: ${poi.gameX}, ${poi.gameY}', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(poi.description),
                  const SizedBox(height: 24),
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
