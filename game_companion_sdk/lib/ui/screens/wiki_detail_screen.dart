import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../sdk/models/wiki_item.dart';
import '../../sdk/models/map_poi.dart';
import '../../sdk/widgets/app_cached_image.dart';
import '../providers/map_providers.dart';
import '../../sdk/map/coords_helper.dart';
import '../../sdk/map/target_map_position_provider.dart';
import '../utils/wiki_icon_helper.dart';

class WikiDetailScreen extends ConsumerWidget {
  final WikiItem item;
  const WikiDetailScreen({super.key, required this.item});

  Color _getStatColor(String statName, Color defaultColor) {
    final s = statName.toLowerCase();
    if (s.contains('speed') || s.contains('fire rate')) return const Color(0xFFFFB300);
    if (s.contains('damage') || s.contains('accel')) return const Color(0xFFFF3D00);
    if (s.contains('handling') || s.contains('accuracy')) return const Color(0xFF00E676);
    if (s.contains('braking') || s.contains('range')) return const Color(0xFF00B0FF);
    return defaultColor;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = getWikiItemMetadata(item);
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
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              try {
                context.go('/wiki');
              } catch (_) {}
            }
          },
        ),
        title: Text(item.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Icon(meta.icon, color: meta.accentColor),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Showcase Banner
          Stack(
            children: [
              Container(
                height: 230,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1E2026),
                      Color(0xFF141519),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: meta.accentColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: AppCachedImage(
                      imageUrl: item.thumbnailUrl,
                      height: 190,
                      fit: BoxFit.contain,
                      fallbackIcon: meta.icon,
                      fallbackColor: meta.accentColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: meta.accentColor.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(meta.icon, size: 14, color: meta.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        '${item.category} • ${meta.subType}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1.5,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(meta.icon, size: 16, color: meta.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        item.category,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: meta.accentColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.4),
                  ),
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
          if (item.stats.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(Icons.bar_chart, size: 22, color: meta.accentColor),
                const SizedBox(width: 8),
                Text('Statistics', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 1.5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: item.stats.entries.map((e) {
                    final double statValue = (e.value is num) ? (e.value as num).toDouble() : 0.0;
                    final String formattedValue = '${(statValue * 100).toStringAsFixed(0)}%';
                    final statColor = _getStatColor(e.key, meta.accentColor);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(e.key, style: Theme.of(context).textTheme.titleSmall),
                              Text(
                                formattedValue,
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: statColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: statValue,
                            minHeight: 10,
                            borderRadius: BorderRadius.circular(5),
                            color: statColor,
                            backgroundColor: statColor.withValues(alpha: 0.15),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
