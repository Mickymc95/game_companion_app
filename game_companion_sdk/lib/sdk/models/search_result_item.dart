import 'map_poi.dart';
import 'wiki_item.dart';

sealed class SearchResultItem {
  final String title;
  final String subtitle;

  SearchResultItem({
    required this.title,
    required this.subtitle,
  });
}

class MapPoiSearchResult extends SearchResultItem {
  final MapPointOfInterest poi;

  MapPoiSearchResult({
    required super.title,
    required super.subtitle,
    required this.poi,
  });
}

class WikiSearchResult extends SearchResultItem {
  final WikiItem item;

  WikiSearchResult({
    required super.title,
    required super.subtitle,
    required this.item,
  });
}
