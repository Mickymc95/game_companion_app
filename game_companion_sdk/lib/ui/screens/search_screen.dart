import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_providers.dart';
import '../../sdk/models/search_result_item.dart';
import '../../sdk/models/map_poi.dart';
import '../../sdk/models/wiki_item.dart';
import '../../sdk/map/coords_helper.dart';
import '../../sdk/map/target_map_position_provider.dart';
import '../../sdk/storage/collection_tracker.dart';
import '../utils/wiki_icon_helper.dart';
import '../utils/poi_style_helper.dart';
import '../../sdk/models/guide_article.dart';
import '../widgets/wiki_item_thumbnail.dart';

class SearchScreen extends ConsumerWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  Widget _buildMapPoiLeading(MapPointOfInterest poi, bool isCollected) {
    final style = getPoiStyle(poi);
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: style.color.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: style.color.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: style.color.withValues(alpha: 0.25),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              style.icon,
              color: style.color,
              size: 22,
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
              size: 12,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.trim().toLowerCase()) {
      case 'beginner':
        return const Color(0xFF4CAF50); // Green
      case 'intermediate':
        return const Color(0xFFFFB300); // Amber
      case 'advanced':
        return const Color(0xFFFF5252); // Red
      default:
        return Colors.blueGrey;
    }
  }

  Widget _buildGuideLeading(BuildContext context, GuideArticle? guide) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final hasVideo = guide?.videoUrl != null && guide!.videoUrl!.isNotEmpty;

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.18),
            shape: BoxShape.circle,
            border: Border.all(
              color: accentColor.withValues(alpha: 0.7),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.menu_book,
              color: accentColor,
              size: 20,
            ),
          ),
        ),
        if (hasVideo)
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFE50914),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(2),
            child: const Icon(
              Icons.videocam,
              size: 11,
              color: Colors.white,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(unifiedSearchResultsProvider(query));

    Set<String> collectedIds = const {};
    try {
      collectedIds = ref.watch(collectionTrackerProvider);
    } catch (_) {
      // Graceful fallback if SharedPreferences is not registered in testing harness
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          query.trim().isEmpty
              ? 'Search Results'
              : 'Search Results for "$query"',
        ),
      ),
      body: searchResultsAsync.when(
        data: (results) {
          if (results.isEmpty) {
            return const Center(child: Text('No results found.'));
          }

          final mapResults = results.where((r) => r.type == SearchResultType.mapPoi).toList();
          final wikiResults = results.where((r) => r.type == SearchResultType.wikiItem).toList();
          final guideResults = results.where((r) => r.type == SearchResultType.guideArticle).toList();

          return CustomScrollView(
            slivers: [
              if (mapResults.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Map Locations', style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = mapResults[index];
                      final poi = item.payload is MapPointOfInterest
                          ? item.payload as MapPointOfInterest
                          : null;
                      final isCollected = poi != null &&
                          poi.isCollectable &&
                          collectedIds.contains(poi.id);
                      final style = poi != null ? getPoiStyle(poi) : null;

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: poi != null
                            ? _buildMapPoiLeading(poi, isCollected)
                            : const Icon(Icons.location_on),
                        title: Text(item.title),
                        subtitle: style != null
                            ? Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: style.color.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      style.label,
                                      style: TextStyle(
                                        color: style.color,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  if (isCollected) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check, size: 12, color: Colors.greenAccent),
                                          SizedBox(width: 2),
                                          Text(
                                            'Found',
                                            style: TextStyle(
                                              color: Colors.greenAccent,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              )
                            : Text(item.subtitle),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          if (poi != null) {
                            final coords = inGameToMapCoords(poi.gameX, poi.gameY);
                            ref.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
                              position: coords,
                              zoom: 4.5,
                              poiId: poi.id,
                              shakeAndOpenCard: true,
                            );
                            context.go('/map');
                          }
                        },
                      );
                    },
                    childCount: mapResults.length,
                  ),
                ),
              ],

              if (wikiResults.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Wiki Entries', style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = wikiResults[index];
                      final wikiItem = item.payload is WikiItem ? item.payload as WikiItem : null;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: wikiItem != null
                            ? WikiItemThumbnail(item: wikiItem)
                            : const Icon(Icons.library_books),
                        title: Text(item.title),
                        subtitle: wikiItem != null
                            ? Builder(
                                builder: (context) {
                                  final meta = getWikiItemMetadata(wikiItem);
                                  return Row(
                                    children: [
                                      Text(
                                        item.subtitle,
                                        style: TextStyle(
                                          color: meta.accentColor,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (meta.subType.isNotEmpty && meta.subType != item.subtitle) ...[
                                        Text(
                                          ' • ${meta.subType}',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                                        ),
                                      ],
                                    ],
                                  );
                                },
                              )
                            : Text(item.subtitle),
                        onTap: () {
                          if (wikiItem != null) {
                            context.push('/wiki/detail', extra: wikiItem);
                          }
                        },
                      );
                    },
                    childCount: wikiResults.length,
                  ),
                ),
              ],

              if (guideResults.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Guides & Tutorials', style: Theme.of(context).textTheme.titleMedium),
                  ),
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = guideResults[index];
                      final guide = item.payload is GuideArticle ? item.payload as GuideArticle : null;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: guide != null
                            ? _buildGuideLeading(context, guide)
                            : const Icon(Icons.menu_book),
                        title: Text(item.title),
                        subtitle: guide != null
                            ? Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        guide.category,
                                        style: TextStyle(
                                          color: Theme.of(context).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getDifficultyColor(guide.difficulty).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        guide.difficulty,
                                        style: TextStyle(
                                          color: _getDifficultyColor(guide.difficulty),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${guide.readTimeMinutes} min',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                                    ),
                                  ],
                                ),
                              )
                            : Text(item.subtitle),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () {
                          context.go('/guides');
                        },
                      );
                    },
                    childCount: guideResults.length,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
