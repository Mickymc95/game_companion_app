import '../../sdk/models/map_poi.dart';
import '../../sdk/models/wiki_item.dart';
import '../../sdk/models/guide_article.dart';

class GTAVFixtures {
  static const String mapTileUrl = 'https://example.com/gtav_tiles/{z}/{x}/{y}.png';
  static const String fallbackMapAsset = 'assets/maps/fallback_tile.png';

  static List<MapPointOfInterest> get mapMarkers => [
    MapPointOfInterest(
      id: 'spaceship_part_01',
      name: 'Spaceship Part #1',
      category: 'collectibles',
      subCategory: 'spaceship_parts',
      gameX: -1124.5,
      gameY: 4812.1,
      description: 'Located on top of the Mount Chiliad observation platform.',
      imageUrl: null,
      isCollectable: true,
    ),
    MapPointOfInterest(
      id: 'stunt_jump_01',
      name: 'Stunt Jump #1 - Del Perro Pier',
      category: 'stunts',
      subCategory: 'stunt_jumps',
      gameX: -1650.0,
      gameY: -1020.0,
      description: 'Jump off the wooden ramp near the end of Del Perro Pier onto the beach below.',
      imageUrl: null,
      isCollectable: true,
    ),
    MapPointOfInterest(
      id: 'ammunation_pillbox',
      name: 'Ammu-Nation Pillbox Hill',
      category: 'services',
      subCategory: 'ammunation',
      gameX: 243.5,
      gameY: -1089.2,
      description: 'Includes an indoor shooting range to level up weapon skills.',
      imageUrl: null,
      isCollectable: false,
    ),
  ];

  static List<WikiItem> get wikiItems => [
    WikiItem(
      id: 'w_1',
      title: 'Carbine Rifle',
      category: 'Weapons',
      stats: {'Damage': 30, 'Accuracy': 55, 'Fire Rate': 65},
      description: 'A standard assault rifle.',
      thumbnailUrl: 'https://via.placeholder.com/150',
    ),
    WikiItem(
      id: 'v_1',
      title: 'Adder',
      category: 'Vehicles',
      stats: {'Speed': 85, 'Acceleration': 80, 'Handling': 75},
      description: 'A very fast supercar.',
      thumbnailUrl: 'https://via.placeholder.com/150',
    ),
  ];

  static List<GuideArticle> get guides => [
    GuideArticle(
      id: 'g_1',
      title: 'How to make money fast',
      tags: ['Money', 'Beginner'],
      contentMarkdown: '''
# Making Money in Los Santos
Here are a few quick tips...
1. Do the Lester Assassination missions after the main story.
2. Invest in the stock market.
      ''',
      videoUrl: 'https://youtube.com/watch?v=dQw4w9WgXcQ',
    )
  ];
}
