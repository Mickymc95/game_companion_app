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

  factory WikiItem.fromJson(Map<String, dynamic> json) {
    return WikiItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      category: json['category'] as String? ?? 'Uncategorized',
      stats: json['stats'] as Map<String, dynamic>? ?? {},
      description: json['description'] as String? ?? '',
      thumbnailUrl: json['thumbnailUrl'] as String? ?? '',
    );
  }
}
