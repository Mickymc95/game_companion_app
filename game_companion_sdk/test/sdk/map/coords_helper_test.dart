import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/map/coords_helper.dart';

void main() {
  test('inGameToMapCoords handles bounds correctly', () {
    // GTA V coords at max bounds map approximately correctly
    final coords = inGameToMapCoords(-4000, -4000);
    // mapX = (-4000 + 4000) * ... = 0
    // mapY = -(-4000 + 4000) * ... = 0
    expect(coords.longitude, 0); // mapX -> lng
    expect(coords.latitude, 0);  // mapY -> lat
  });
}
