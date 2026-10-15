enum SearchResultType {
  mapPoi,
  wikiItem,
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
