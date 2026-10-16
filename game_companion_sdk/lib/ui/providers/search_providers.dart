import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sdk/models/search_result_item.dart';
import '../../sdk/models/map_poi.dart';
import '../../sdk/models/wiki_item.dart';
import 'map_providers.dart';
import 'wiki_providers.dart';

final unifiedSearchResultsProvider = FutureProvider.family<List<SearchResultItem>, String>((ref, query) async {
  final lowerQuery = query.toLowerCase().trim();
  final results = <SearchResultItem>[];

  if (lowerQuery.isEmpty) {
    return results;
  }

  // Fetch map POIs, falling back to empty list on error
  final pois = await ref.watch(mapPoiProvider.future).catchError((_) => <MapPointOfInterest>[]);
  for (final poi in pois) {
    if (poi.name.toLowerCase().contains(lowerQuery) || poi.description.toLowerCase().contains(lowerQuery)) {
      results.add(MapPoiSearchResult(
        title: poi.name,
        subtitle: poi.category,
        poi: poi,
      ));
    }
  }

  // Fetch wiki items, falling back to empty list on error
  final wikiItems = await ref.watch(wikiItemsProvider.future).catchError((_) => <WikiItem>[]);
  for (final item in wikiItems) {
    if (item.title.toLowerCase().contains(lowerQuery) || item.description.toLowerCase().contains(lowerQuery)) {
      results.add(WikiSearchResult(
        title: item.title,
        subtitle: item.category,
        item: item,
      ));
    }
  }

  return results;
});
