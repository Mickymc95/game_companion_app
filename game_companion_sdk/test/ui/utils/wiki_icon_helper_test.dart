import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/models/wiki_item.dart';
import 'package:game_companion_sdk/ui/utils/wiki_icon_helper.dart';

void main() {
  group('WikiIconHelper Tests', () {
    test('Correctly maps supercars to speed icon and Supercar subType', () {
      final item = WikiItem(
        id: 'v_adder',
        title: 'Truffade Adder',
        category: 'Vehicles',
        stats: {},
        description: 'Supercar',
        thumbnailUrl: 'assets/media/gtav/vehicles/adder.webp',
      );

      final meta = getWikiItemMetadata(item);
      expect(meta.icon, Icons.speed);
      expect(meta.subType, 'Supercar');
      expect(meta.accentColor, const Color(0xFFFFB300));
    });

    test('Correctly maps motorcycles to two_wheeler icon', () {
      final item = WikiItem(
        id: 'v_bati_801',
        title: 'Pegassi Bati 801',
        category: 'Vehicles',
        stats: {},
        description: 'Motorcycle',
        thumbnailUrl: 'assets/media/gtav/vehicles/bati_801.webp',
      );

      final meta = getWikiItemMetadata(item);
      expect(meta.icon, Icons.two_wheeler);
      expect(meta.subType, 'Motorcycle');
      expect(meta.accentColor, const Color(0xFF00E676));
    });

    test('Correctly maps aircraft to flight icon', () {
      final item = WikiItem(
        id: 'v_hydra',
        title: 'Mammoth Hydra',
        category: 'Vehicles',
        stats: {},
        description: 'Jet',
        thumbnailUrl: 'assets/media/gtav/vehicles/hydra.webp',
      );

      final meta = getWikiItemMetadata(item);
      expect(meta.icon, Icons.flight);
      expect(meta.subType, 'Aircraft');
    });

    test('Correctly maps handguns to security icon', () {
      final item = WikiItem(
        id: 'w_pistol',
        title: 'Standard Pistol',
        category: 'Weapons',
        stats: {},
        description: 'Pistol',
        thumbnailUrl: 'assets/media/gtav/weapons/pistol.webp',
      );

      final meta = getWikiItemMetadata(item);
      expect(meta.icon, Icons.security);
      expect(meta.subType, 'Handgun');
    });

    test('Correctly maps sniper rifles to filter_center_focus icon', () {
      final item = WikiItem(
        id: 'w_heavy_sniper',
        title: 'Heavy Sniper',
        category: 'Weapons',
        stats: {},
        description: 'Sniper',
        thumbnailUrl: 'assets/media/gtav/weapons/heavy_sniper.webp',
      );

      final meta = getWikiItemMetadata(item);
      expect(meta.icon, Icons.filter_center_focus);
      expect(meta.subType, 'Sniper');
    });

    test('Correctly maps heavy weapons to rocket_launch icon', () {
      final item = WikiItem(
        id: 'w_rpg',
        title: 'RPG',
        category: 'Weapons',
        stats: {},
        description: 'Rocket launcher',
        thumbnailUrl: 'assets/media/gtav/weapons/rpg.webp',
      );

      final meta = getWikiItemMetadata(item);
      expect(meta.icon, Icons.rocket_launch);
      expect(meta.subType, 'Heavy');
    });

    test('Fallback for unknown items returns generic icon', () {
      final item = WikiItem(
        id: 'custom_99',
        title: 'Alien Artifact',
        category: 'Collectibles',
        stats: {},
        description: 'Unknown',
        thumbnailUrl: '',
      );

      final meta = getWikiItemMetadata(item);
      expect(meta.icon, Icons.category);
      expect(meta.subType, 'General');
    });
  });
}
