class WikiItem {
  final String id;
  final String title;
  final String category;
  final Map<String, dynamic> stats;
  final String description;
  final String thumbnailUrl;

  WikiItem({
    required this.id,
    required this.title,
    required this.category,
    required this.stats,
    required this.description,
    required this.thumbnailUrl,
  });
}
