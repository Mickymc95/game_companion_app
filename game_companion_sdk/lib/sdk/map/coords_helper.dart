import 'dart:math' as math;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/map_poi.dart';

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

/// Panning bounds with generous margin around the island so users can pan
/// smoothly without hitting rigid boundaries.
final LatLngBounds kGtaMapPanBounds = LatLngBounds(
  const LatLng(kGtaMapSize * 0.4, -kGtaMapSize * 0.4),
  const LatLng(-kGtaMapSize * 1.4, kGtaMapSize * 1.4),
);

/// Centre of the map image in CrsSimple coordinates.
const LatLng kGtaMapCenter = LatLng(-kGtaMapSize / 2, kGtaMapSize / 2);

LatLng inGameToMapCoords(double gameX, double gameY) {
  final double mapX = (gameX - _gameLeftX) / _gameUnitsPerMapUnit;
  // Higher in-game Y is further north, i.e. closer to the top of the image.
  final double mapY = -(_gameTopY - gameY) / _gameUnitsPerMapUnit;
  return LatLng(mapY, mapX);
}

/// Calculate standard Euclidean distance between two points in in-game coordinate space.
double distanceBetweenInGameCoords(double x1, double y1, double x2, double y2) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  return math.sqrt(dx * dx + dy * dy);
}

/// Finds the closest uncollected [MapPointOfInterest] to [fromPoi] from a collection of candidates.
/// Excludes the [fromPoi] itself if present in [candidates].
MapPointOfInterest? findNearestPoi(
  MapPointOfInterest fromPoi,
  Iterable<MapPointOfInterest> candidates,
) {
  MapPointOfInterest? nearest;
  double minDistance = double.infinity;

  for (final candidate in candidates) {
    if (candidate.id == fromPoi.id) continue;
    final dist = distanceBetweenInGameCoords(
      fromPoi.gameX,
      fromPoi.gameY,
      candidate.gameX,
      candidate.gameY,
    );
    if (dist < minDistance) {
      minDistance = dist;
      nearest = candidate;
    }
  }

  return nearest;
}

