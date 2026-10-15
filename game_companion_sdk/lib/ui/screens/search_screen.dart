import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_providers.dart';
import '../../sdk/models/search_result_item.dart';
import '../../sdk/models/map_poi.dart';
import '../../sdk/models/wiki_item.dart';
import '../../sdk/map/coords_helper.dart';
import '../../sdk/map/target_map_position_provider.dart';
import '../utils/wiki_icon_helper.dart';
import '../widgets/wiki_item_thumbnail.dart';

class SearchScreen extends ConsumerWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchResultsAsync = ref.watch(unifiedSearchResultsProvider(query));

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
                      return ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                        onTap: () {
                          final poi = item.payload as MapPointOfInterest;
                          final coords = inGameToMapCoords(poi.gameX, poi.gameY);
                          ref.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
                            position: coords,
                            zoom: 4.5,
                            poiId: poi.id,
                          );
                          context.go('/map');
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
              ]
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
