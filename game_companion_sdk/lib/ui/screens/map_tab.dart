import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../sdk/map/game_map.dart';
import '../../games/gtav/fixtures.dart';
import '../../sdk/storage/collection_tracker.dart';

class MapTab extends ConsumerWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collectedState = ref.watch(collectionTrackerProvider);
    // Simple filter state for demo purposes. In a real app, use Riverpod.
    // We'll show all markers for now, but demonstrate the filter UI.

    final markers = GTAVFixtures.mapMarkers.map((poi) {
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

    return Scaffold(
      body: GameMap(
        tileUrlTemplate: GTAVFixtures.mapTileUrl,
        fallbackAsset: GTAVFixtures.fallbackMapAsset,
        markers: markers,
        bounds: LatLngBounds(const LatLng(-100, -100), const LatLng(100, 100)), // Dummy bounds for CRS.simple
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.filter_list),
        onPressed: () {
          _showFilterSheet(context);
        },
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        final categories = GTAVFixtures.mapMarkers.map((m) => m.category).toSet().toList();
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
                    selected: true, // Demo: all selected
                    onSelected: (bool value) {
                      // Handle filter logic via Riverpod provider in real implementation
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
