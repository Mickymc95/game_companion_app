import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sdk/models/guide_article.dart';
import '../../sdk/models/search_result_item.dart';
import 'guides_provider.dart';
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

  // Fetch guides
  final guides = await ref.watch(guidesProvider.future);
  for (final guide in guides) {
    final matchesTitle = guide.title.toLowerCase().contains(lowerQuery);
    final matchesCategory = guide.category.toLowerCase().contains(lowerQuery);
    final matchesTags = guide.tags.any((t) => t.toLowerCase().contains(lowerQuery));
    final matchesContent = guide.contentMarkdown.toLowerCase().contains(lowerQuery);

    if (matchesTitle || matchesCategory || matchesTags || matchesContent) {
      results.add(SearchResultItem(
        title: guide.title,
        subtitle: '${guide.category} • ${guide.difficulty} • ${guide.readTimeMinutes} min',
        type: SearchResultType.guideArticle,
        payload: guide,
      ));
    }
  }

  return results;
});
