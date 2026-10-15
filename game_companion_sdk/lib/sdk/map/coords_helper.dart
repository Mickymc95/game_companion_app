import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Size (in CrsSimple map units) of the GTA V map image served by
/// https://gta5-map.github.io/tiles/.
///
/// In flutter_map, `CrsSimple` uses a scale of `256 * 2^zoom`, so one map unit
/// equals one whole 256px tile at zoom 0. The gta5-map tileset is anchored at
/// the top-left of the tile grid and the island image covers 43 tiles at
/// zoom 7, i.e. 43 / 2^7 units.
const double kGtaMapSize = 43.0 / 128.0;

/// Approximate calibration from in-game coordinates to the tile image.
/// The image is square and covers roughly 12,250 in-game units per side.
/// Tweak these constants against a known landmark if markers look offset.
const double _gameLeftX = -5900.0; // in-game X at the left edge of the image
const double _gameTopY = 8300.0; // in-game Y at the top edge of the image
const double _gameUnitsPerMapUnit = 12250.0 / kGtaMapSize;

/// Bounds of the map image in CrsSimple coordinates (lat grows upward, so the
/// image spans lat 0 → -kGtaMapSize and lng 0 → kGtaMapSize).
final LatLngBounds kGtaMapBounds = LatLngBounds(
  const LatLng(0, 0),
  const LatLng(-kGtaMapSize, kGtaMapSize),
);

/// Centre of the map image in CrsSimple coordinates.
const LatLng kGtaMapCenter = LatLng(-kGtaMapSize / 2, kGtaMapSize / 2);

LatLng inGameToMapCoords(double gameX, double gameY) {
  final double mapX = (gameX - _gameLeftX) / _gameUnitsPerMapUnit;
  // Higher in-game Y is further north, i.e. closer to the top of the image.
  final double mapY = -(_gameTopY - gameY) / _gameUnitsPerMapUnit;
  return LatLng(mapY, mapX);
}
