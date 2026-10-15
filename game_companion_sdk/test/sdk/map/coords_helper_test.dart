import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/map/coords_helper.dart';

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
}
