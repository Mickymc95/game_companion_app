enum SearchResultType {
  mapPoi,
  wikiItem,
  guideArticle,
}

class SearchResultItem {
  final String title;
  final String subtitle;
  final SearchResultType type;
  final dynamic payload;

  SearchResultItem({
    required this.title,
    required this.subtitle,
    required this.type,
    required this.payload,
  });
}
