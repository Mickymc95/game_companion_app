class MapPointOfInterest {
  final String id;
  final String name;
  final String category;
  final String subCategory;
  final double gameX;
  final double gameY;
  final String description;
  final String? imageUrl;
  final bool isCollectable;
  final String? takeoffDirection;
  final String? landingZone;
  final String? vehicleRecommendation;

  MapPointOfInterest({
    required this.id,
    required this.name,
    required this.category,
    required this.subCategory,
    required this.gameX,
    required this.gameY,
    required this.description,
    this.imageUrl,
    this.isCollectable = false,
    this.takeoffDirection,
    this.landingZone,
    this.vehicleRecommendation,
  });

  factory MapPointOfInterest.fromJson(Map<String, dynamic> json) {
    return MapPointOfInterest(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      subCategory: json['subCategory'] as String,
      gameX: (json['gameX'] as num).toDouble(),
      gameY: (json['gameY'] as num).toDouble(),
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      isCollectable: json['isCollectable'] as bool? ?? false,
      takeoffDirection: (json['takeoffDirection'] ?? json['takeoff_direction']) as String?,
      landingZone: (json['landingZone'] ?? json['landing_zone']) as String?,
      vehicleRecommendation: (json['vehicleRecommendation'] ?? json['vehicle_recommendation']) as String?,
    );
  }
}
