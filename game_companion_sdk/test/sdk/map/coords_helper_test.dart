import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/map/coords_helper.dart';
import 'package:game_companion_sdk/sdk/models/map_poi.dart';

void main() {
  test('inGameToMapCoords maps the top-left calibration point to origin', () {
    // The in-game point at the top-left corner of the tile image -> (0, 0).
    final coords = inGameToMapCoords(-5900, 8300);
    expect(coords.longitude, closeTo(0, 1e-9)); // mapX -> lng
    expect(coords.latitude, closeTo(0, 1e-9)); // mapY -> lat
  });

  test('inGameToMapCoords keeps in-world points inside the map bounds', () {
    for (final p in [
      [-1124.5, 4812.1],
      [-500.0, 1200.0],
      [0.0, 0.0],
      [3500.0, -3000.0],
    ]) {
      final coords = inGameToMapCoords(p[0], p[1]);
      expect(kGtaMapBounds.contains(coords), isTrue, reason: '$p -> $coords');
    }
  });

  test('north (higher in-game Y) is towards the top of the map', () {
    final south = inGameToMapCoords(0, -3000);
    final north = inGameToMapCoords(0, 7000);
    expect(north.latitude, greaterThan(south.latitude));
  });

  test('distanceBetweenInGameCoords calculates accurate Euclidean distance', () {
    expect(distanceBetweenInGameCoords(0, 0, 300, 400), closeTo(500, 1e-6));
    expect(distanceBetweenInGameCoords(100, 200, 100, 200), 0.0);
  });

  test('findNearestPoi returns the closest candidate excluding self', () {
    final origin = MapPointOfInterest(
      id: 'origin',
      name: 'Origin',
      category: 'collectibles',
      subCategory: 'parts',
      gameX: 0,
      gameY: 0,
      description: '',
      isCollectable: true,
    );
    final close = MapPointOfInterest(
      id: 'close',
      name: 'Close Point',
      category: 'collectibles',
      subCategory: 'parts',
      gameX: 100,
      gameY: 100,
      description: '',
      isCollectable: true,
    );
    final far = MapPointOfInterest(
      id: 'far',
      name: 'Far Point',
      category: 'collectibles',
      subCategory: 'parts',
      gameX: 1000,
      gameY: 1000,
      description: '',
      isCollectable: true,
    );

    final nearest = findNearestPoi(origin, [origin, far, close]);
    expect(nearest?.id, 'close');
  });

  test('findNearestPoi returns null when candidates list is empty or only contains origin', () {
    final origin = MapPointOfInterest(
      id: 'origin',
      name: 'Origin',
      category: 'collectibles',
      subCategory: 'parts',
      gameX: 0,
      gameY: 0,
      description: '',
      isCollectable: true,
    );

    expect(findNearestPoi(origin, []), isNull);
    expect(findNearestPoi(origin, [origin]), isNull);
  });
}
