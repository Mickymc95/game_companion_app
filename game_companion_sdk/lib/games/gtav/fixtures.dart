import '../../sdk/models/map_poi.dart';
import '../../sdk/models/wiki_item.dart';
import '../../sdk/models/guide_article.dart';

class GTAVFixtures {
  static const String mapTileUrl = 'https://example.com/gtav_tiles/{z}/{x}/{y}.png';
  static const String fallbackMapAsset = 'assets/maps/fallback_tile.png';

  static List<MapPointOfInterest> get mapMarkers => [
    MapPointOfInterest(
      id: 'poi_1',
      title: 'Spaceship Part 1',
      category: 'Collectibles',
      x: 10,
      y: 10,
      description: 'Found near the old barn.',
      icon: 'spaceship',
      isCollectable: true,
    ),
    MapPointOfInterest(
      id: 'poi_2',
      title: 'Ammu-Nation',
      category: 'Services',
      x: -5,
      y: 15,
      description: 'Buy weapons and armor.',
      icon: 'weapon',
    ),
    MapPointOfInterest(
      id: 'poi_3',
      title: 'Stunt Jump 1',
      category: 'Stunt Jumps',
      x: 20,
      y: -10,
      description: 'Jump over the highway.',
      icon: 'jump',
      isCollectable: true,
    )
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
