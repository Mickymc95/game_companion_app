import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/search_providers.dart';
import '../../sdk/models/search_result_item.dart';
import '../../sdk/map/coords_helper.dart';
import '../../sdk/map/target_map_position_provider.dart';

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

          final mapResults = results.whereType<MapPoiSearchResult>().toList();
          final wikiResults = results.whereType<WikiSearchResult>().toList();

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
                          final poi = item.poi;
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
                      return ListTile(
                        leading: const Icon(Icons.library_books),
                        title: Text(item.title),
                        subtitle: Text(item.subtitle),
                        onTap: () {
                          context.push('/wiki/detail', extra: item.item);
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
