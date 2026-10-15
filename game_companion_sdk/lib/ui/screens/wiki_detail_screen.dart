import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../sdk/models/wiki_item.dart';
import '../../sdk/models/map_poi.dart';
import '../../sdk/widgets/app_cached_image.dart';
import '../providers/map_providers.dart';
import '../../sdk/map/coords_helper.dart';
import '../../sdk/map/target_map_position_provider.dart';

class WikiDetailScreen extends ConsumerWidget {
  final WikiItem item;
  const WikiDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Attempt to find a matching POI
    final mapPoisAsync = ref.watch(mapPoiProvider);
    final allPois = mapPoisAsync.valueOrNull ?? [];

    final matchingPoi = allPois.cast<MapPointOfInterest?>().firstWhere(
      (poi) => poi != null && (
        poi.name.trim().toLowerCase() == item.title.trim().toLowerCase() ||
        poi.id.trim().toLowerCase() == item.id.trim().toLowerCase()
      ),
      orElse: () => null,
    );

    return Scaffold(
      appBar: AppBar(title: Text(item.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCachedImage(
            imageUrl: item.thumbnailUrl,
            height: 200,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.category, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Text(item.description, style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          if (matchingPoi != null) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('View on Map'),
                onPressed: () {
                  final coords = inGameToMapCoords(matchingPoi.gameX, matchingPoi.gameY);
                  ref.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
                    position: coords,
                    zoom: 4.5,
                    poiId: matchingPoi.id,
                  );
                  context.go('/map');
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...item.stats.entries.map((e) {
            final double statValue = (e.value is num) ? (e.value as num).toDouble() : 0.0;
            final String formattedValue = '${(statValue * 100).toStringAsFixed(0)}%';

            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: Theme.of(context).textTheme.titleSmall),
                      Text(formattedValue, style: Theme.of(context).textTheme.labelMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: statValue,
                    minHeight: 12,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}
