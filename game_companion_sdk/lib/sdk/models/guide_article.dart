class GuideArticle {
  final String id;
  final String title;
  final List<String> tags;
  final String contentMarkdown;
  final String? videoUrl;

  GuideArticle({
    required this.id,
    required this.title,
    required this.tags,
    required this.contentMarkdown,
    this.videoUrl,
  });
}
