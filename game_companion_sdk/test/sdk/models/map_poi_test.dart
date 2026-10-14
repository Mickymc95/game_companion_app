import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/models/map_poi.dart';

void main() {
  test('MapPointOfInterest.fromJson parses correctly', () {
    final json = {
      "id": "test_id",
      "name": "Test POI",
      "category": "collectibles",
      "subCategory": "parts",
      "gameX": 100.5,
      "gameY": 200.5,
      "description": "desc",
      "imageUrl": null,
      "isCollectable": true
    };

    final poi = MapPointOfInterest.fromJson(json);

    expect(poi.id, 'test_id');
    expect(poi.name, 'Test POI');
    expect(poi.category, 'collectibles');
    expect(poi.gameX, 100.5);
    expect(poi.gameY, 200.5);
    expect(poi.isCollectable, true);
  });
}
