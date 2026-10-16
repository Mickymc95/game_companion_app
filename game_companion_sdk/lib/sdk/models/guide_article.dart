class GuideArticle {
  final String id;
  final String title;
  final String category;
  final List<String> tags;
  final String difficulty;
  final int readTimeMinutes;
  final String contentMarkdown;
  final String? videoUrl;

  const GuideArticle({
    required this.id,
    required this.title,
    this.category = 'General',
    required this.tags,
    this.difficulty = 'Intermediate',
    this.readTimeMinutes = 5,
    required this.contentMarkdown,
    this.videoUrl,
  });

  factory GuideArticle.fromJson(Map<String, dynamic> json) {
    return GuideArticle(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const <String>[],
      difficulty: json['difficulty'] as String? ?? 'Intermediate',
      readTimeMinutes: (json['readTimeMinutes'] as num?)?.toInt() ?? 5,
      contentMarkdown: json['contentMarkdown'] as String? ?? '',
      videoUrl: json['videoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'tags': tags,
      'difficulty': difficulty,
      'readTimeMinutes': readTimeMinutes,
      'contentMarkdown': contentMarkdown,
      'videoUrl': videoUrl,
    };
  }

  String? get youtubeVideoId {
    if (videoUrl == null || videoUrl!.isEmpty) return null;
    final match = RegExp(r'(?:v=|\/)([0-9A-Za-z_-]{11})(?:[&?]|\b|$)').firstMatch(videoUrl!);
    return match?.group(1);
  }

  String? get youtubeThumbnailUrl {
    final videoId = youtubeVideoId;
    if (videoId == null) return null;
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }
}
