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

  static List<GuideArticle> get guides => const [
    GuideArticle(
      id: 'guide_money_lester_stock_market',
      title: 'Lester Assassination Stock Market Guide: Maximize Billions',
      category: 'Money & Stock Market',
      tags: ['Money', 'Stock Market', 'Lester', 'Investing'],
      difficulty: 'Intermediate',
      readTimeMinutes: 7,
      contentMarkdown: '''# Lester Assassination Stock Market Investment Strategy

Maximizing your wealth in Grand Theft Auto V requires careful timing of Lester Crest's assassination missions. By coordinating investments across Michael, Franklin, and Trevor, each protagonist can amass upwards of \$2.1 billion.

## Fundamental Rules
1. **Complete the Main Story First**: Complete "The Big Score" before tackling Lester's assassinations beyond the mandatory Hotel Assassination. This gives each character approximately \$25-30 million to invest.
2. **Invest All Three Characters**: Before initiating each mission, switch between all three characters and invest 100% of their cash portfolios into the targeted stock.
3. **Save and Sleep to Advance Market Cycles**: Use the character beds to skip time (6-8 hours per sleep) and monitor peak percentage yields.

## Step-by-Step Mission Breakdown
- **Hotel Assassination**: Invest in Betta Pharmaceuticals (BET) on BAWSAQ before the job. Sell at ~80% profit. Later, invest in Bilkinton (BIL) on LCN after it drops; sell after rebound (~100% profit).
- **The Multi Target Assassination**: Invest in Debonaire (DEB) on LCN before the mission. Sell at ~80% profit. Reinvest immediately in Redwood (RWD) on LCN; sell at ~300% profit.
- **The Vice Assassination**: Invest in Fruit (FRT) on BAWSAQ before the mission. Sell at ~50% profit. Reinvest in Facade (FAC) on BAWSAQ for ~30% profit.
- **The Bus Assassination**: Complete the mission first, then invest in Vapid (VAP) on BAWSAQ after its stock tanks. Sell when it rebounds at ~100% profit.
- **The Construction Assassination**: Invest in GoldCoast (GCD) on LCN prior to starting. Sell at ~80% profit.
''',
      videoUrl: 'https://www.youtube.com/watch?v=hG7W5v6J7Z0',
    ),
  ];
}
