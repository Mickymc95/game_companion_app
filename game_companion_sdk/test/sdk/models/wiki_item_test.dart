import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/models/wiki_item.dart';

void main() {
  group('WikiItem', () {
    test('fromJson deserializes correctly', () {
      final json = {
        'id': 'v_adder',
        'title': 'Adder',
        'category': 'Vehicles',
        'stats': {
          'Speed': 0.85,
          'Acceleration': 0.80,
        },
        'description': 'A very fast supercar.',
        'thumbnailUrl': 'https://example.com/adder.png'
      };

      final item = WikiItem.fromJson(json);

      expect(item.id, 'v_adder');
      expect(item.title, 'Adder');
      expect(item.category, 'Vehicles');
      expect(item.description, 'A very fast supercar.');
      expect(item.thumbnailUrl, 'https://example.com/adder.png');
      expect(item.stats, isA<Map<String, dynamic>>());
      expect(item.stats['Speed'], 0.85);
      expect(item.stats['Acceleration'], 0.80);
    });

    test('fromJson handles missing values safely', () {
      final json = <String, dynamic>{};

      final item = WikiItem.fromJson(json);

      expect(item.id, '');
      expect(item.title, 'Unknown');
      expect(item.category, 'Uncategorized');
      expect(item.description, '');
      expect(item.thumbnailUrl, '');
      expect(item.stats, isEmpty);
    });
  });
}
