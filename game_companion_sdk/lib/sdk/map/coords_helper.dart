import 'package:latlong2/latlong.dart';

LatLng inGameToMapCoords(double gameX, double gameY) {
  final double mapX = (gameX + 4000.0) * (8192.0 / 8500.0);
  final double mapY = -(gameY + 4000.0) * (8192.0 / 12000.0);
  return LatLng(mapY, mapX);
}
