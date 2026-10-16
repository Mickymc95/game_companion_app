import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/models/map_poi.dart';
import 'package:game_companion_sdk/ui/utils/poi_style_helper.dart';

void main() {
  group('PoiStyleHelper Tests', () {
    test('Returns distinct icons and labels for all 14 subcategories', () {
      final subcategories = [
        'spaceship_parts',
        'letter_scraps',
        'submarine_pieces',
        'nuclear_waste',
        'peyote_plants',
        'stunt_jumps',
        'under_the_bridge',
        'knife_flights',
        'properties',
        'safehouses',
        'ammunation',
        'secrets_easter_eggs',
        'vehicle_spawns',
        'encounters',
      ];

      final styles = subcategories.map((sub) => getPoiStyleForSubcategory(sub)).toList();

      for (int i = 0; i < subcategories.length; i++) {
        final sub = subcategories[i];
        final style = styles[i];

        expect(style.label, isNotEmpty, reason: '$sub must have a non-empty label');
        expect(style.icon, isNotNull, reason: '$sub must have an icon');
        expect(style.color, isNotNull, reason: '$sub must have a color');
      }

      // Check specific expected mappings
      expect(getPoiStyleForSubcategory('spaceship_parts').icon, Icons.rocket_launch);
      expect(getPoiStyleForSubcategory('letter_scraps').icon, Icons.mark_email_unread);
      expect(getPoiStyleForSubcategory('submarine_pieces').icon, Icons.sailing);
      expect(getPoiStyleForSubcategory('nuclear_waste').icon, Icons.warning_amber);
      expect(getPoiStyleForSubcategory('peyote_plants').icon, Icons.eco);
      expect(getPoiStyleForSubcategory('stunt_jumps').icon, Icons.sports_motorsports);
      expect(getPoiStyleForSubcategory('under_the_bridge').icon, Icons.flight);
      expect(getPoiStyleForSubcategory('knife_flights').icon, Icons.airplanemode_active);
      expect(getPoiStyleForSubcategory('properties').icon, Icons.apartment);
      expect(getPoiStyleForSubcategory('safehouses').icon, Icons.home);
      expect(getPoiStyleForSubcategory('ammunation').icon, Icons.shield);
      expect(getPoiStyleForSubcategory('secrets_easter_eggs').icon, Icons.auto_awesome);
      expect(getPoiStyleForSubcategory('vehicle_spawns').icon, Icons.directions_car);
      expect(getPoiStyleForSubcategory('encounters').icon, Icons.person_pin_circle);
    });

    test('getPoiStyle resolves correctly from MapPointOfInterest instance', () {
      final poi = MapPointOfInterest(
        id: 'stunt_jump_01',
        name: 'Del Perro Stunt Jump',
        category: 'stunts',
        subCategory: 'stunt_jumps',
        gameX: -1200.0,
        gameY: -800.0,
        description: 'Launch over ramp',
        isCollectable: true,
        takeoffDirection: 'East',
        landingZone: 'Median',
        vehicleRecommendation: 'Bati 801',
      );

      final style = getPoiStyle(poi);
      expect(style.icon, Icons.sports_motorsports);
      expect(style.color, const Color(0xFFFF6D00));
      expect(style.label, 'Stunt Jump');
    });

    test('Fallback style for unknown subcategory', () {
      final style = getPoiStyleForSubcategory('unknown_custom_sub');
      expect(style.icon, Icons.location_on);
      expect(style.label, 'Location');
    });
  });
}
