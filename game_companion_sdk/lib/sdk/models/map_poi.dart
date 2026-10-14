class MapPointOfInterest {
  final String id;
  final String title;
  final String category;
  final double x;
  final double y;
  final String description;
  final String icon;
  final bool isCollectable;

  MapPointOfInterest({
    required this.id,
    required this.title,
    required this.category,
    required this.x,
    required this.y,
    required this.description,
    required this.icon,
    this.isCollectable = false,
  });
}
