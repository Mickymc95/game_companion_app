import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sdk/models/search_result_item.dart';
import 'map_providers.dart';
import 'wiki_providers.dart';

final unifiedSearchResultsProvider = FutureProvider.family<List<SearchResultItem>, String>((ref, query) async {
  final lowerQuery = query.toLowerCase().trim();
  final results = <SearchResultItem>[];

  if (lowerQuery.isEmpty) {
    return results;
  }

  // Fetch map POIs
  final pois = await ref.watch(mapPoiProvider.future);
  for (final poi in pois) {
    if (poi.name.toLowerCase().contains(lowerQuery) || poi.description.toLowerCase().contains(lowerQuery)) {
      results.add(SearchResultItem(
        title: poi.name,
        subtitle: poi.category,
        type: SearchResultType.mapPoi,
        payload: poi,
      ));
    }
  }

  // Fetch wiki items
  final wikiItems = await ref.watch(wikiItemsProvider.future);
  for (final item in wikiItems) {
    if (item.title.toLowerCase().contains(lowerQuery) || item.description.toLowerCase().contains(lowerQuery)) {
      results.add(SearchResultItem(
        title: item.title,
        subtitle: item.category,
        type: SearchResultType.wikiItem,
        payload: item,
      ));
    }
  }

  return results;
});
