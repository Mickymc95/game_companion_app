import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:game_companion_sdk/sdk/models/wiki_item.dart';
import 'package:game_companion_sdk/ui/providers/wiki_providers.dart';
import 'package:game_companion_sdk/ui/providers/map_providers.dart';
import 'package:game_companion_sdk/sdk/models/map_poi.dart';
import 'package:game_companion_sdk/ui/screens/search_screen.dart';
import 'package:game_companion_sdk/sdk/map/target_map_position_provider.dart';
import 'package:game_companion_sdk/ui/widgets/wiki_item_thumbnail.dart';
import 'package:game_companion_sdk/sdk/models/guide_article.dart';
import 'package:game_companion_sdk/ui/providers/guides_provider.dart';

void main() {
  testWidgets('SearchScreen renders empty query correctly in AppBar', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: '   '),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Search Results'), findsOneWidget);
    expect(find.text('Search Results for "   "'), findsNothing);
  });

  testWidgets('SearchScreen queries both POI and Wiki items correctly', (WidgetTester tester) async {
    final mockPois = [
      MapPointOfInterest(
        id: '1',
        name: 'Spaceship Part #1',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: -1124.5,
        gameY: 4812.1,
        description: 'Located on top of the Mount Chiliad observation platform.',
      )
    ];

    final mockWikiItems = [
      WikiItem(
        id: 'w_1',
        title: 'Carbine Rifle',
        category: 'Weapons',
        stats: {},
        description: 'A standard assault rifle.',
        thumbnailUrl: 'https://example.com/loading.webp',
      )
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value(mockWikiItems)),
        mapPoiProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value(mockPois)),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'Carbine'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Wiki Entries'), findsOneWidget);
    expect(find.text('Carbine Rifle'), findsOneWidget);
    expect(find.text('Map Locations'), findsNothing);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value(mockWikiItems)),
        mapPoiProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value(mockPois)),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'Spaceship'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Map Locations'), findsOneWidget);
    expect(find.text('Spaceship Part #1'), findsOneWidget);
    expect(find.text('Wiki Entries'), findsNothing);
  });

  testWidgets('Tapping map POI triggers target position provider', (WidgetTester tester) async {
    final mockWikiItems = <WikiItem>[];

    final mockPois = [
      MapPointOfInterest(
        id: '1',
        name: 'Spaceship Part #1',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: -1124.5,
        gameY: 4812.1,
        description: 'Located on top of the Mount Chiliad observation platform.',
      )
    ];

    final container = ProviderContainer(
      overrides: [
        wikiItemsProvider.overrideWith((ref) => Future.value(mockWikiItems)),
        mapPoiProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value(mockPois)),
      ],
    );

    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(query: 'Spaceship'),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const Scaffold(body: Text('Map View')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on map POI
    await tester.tap(find.text('Spaceship Part #1'));
    await tester.pumpAndSettle();

    // Ensure we navigated to map
    expect(find.text('Map View'), findsOneWidget);

    // Verify provider was set
    final targetPos = container.read(targetMapPositionProvider);
    expect(targetPos, isNotNull);
    expect(targetPos?.zoom, 4.5);
    expect(targetPos?.poiId, isNotNull);
  });

  testWidgets('Tapping Wiki item pushes to wiki detail screen', (WidgetTester tester) async {
    final mockPois = [
      MapPointOfInterest(
        id: '1',
        name: 'Spaceship Part #1',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: -1124.5,
        gameY: 4812.1,
        description: 'Located on top of the Mount Chiliad observation platform.',
      )
    ];

    final mockWikiItems = [
      WikiItem(
        id: 'w_1',
        title: 'Pistol',
        category: 'Weapons',
        stats: {'Damage': 0.5},
        description: 'A standard pistol.',
        thumbnailUrl: '',
      )
    ];

    final container = ProviderContainer(
      overrides: [
        wikiItemsProvider.overrideWith((ref) => Future.value(mockWikiItems)),
        mapPoiProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value(mockPois)),
      ],
    );

    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(query: 'Pistol'),
        ),
        GoRoute(
          path: '/wiki/detail',
          builder: (context, state) {
            final item = state.extra as WikiItem?;
            if (item == null) return const Scaffold(body: Center(child: Text('Item not found')));
            // Assuming WikiDetailScreen is accessible or we mock its view
            // Since WikiDetailScreen requires a WikiItem, we mock it via a dummy text widget
            return Scaffold(body: Text(item.description));
          },
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on wiki item
    await tester.tap(find.text('Pistol').last);
    await tester.pumpAndSettle();

    // Ensure we navigated to wiki detail
    expect(find.text('A standard pistol.'), findsOneWidget);
  });

  testWidgets('SearchScreen renders WikiItemThumbnail and specific category icon for wiki results', (WidgetTester tester) async {
    final mockWikiItems = [
      WikiItem(
        id: 'w_carbine_rifle',
        title: 'Carbine Rifle',
        category: 'Weapons',
        stats: {},
        description: 'A standard assault rifle.',
        thumbnailUrl: '',
      ),
      WikiItem(
        id: 'v_adder',
        title: 'Adder',
        category: 'Vehicles',
        stats: {},
        description: 'High-speed supercar.',
        thumbnailUrl: '',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value(mockWikiItems)),
          mapPoiProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'Carbine'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(WikiItemThumbnail), findsOneWidget);
    // Track changes icon should be displayed for Carbine Rifle
    expect(find.byIcon(Icons.track_changes), findsWidgets);
    // Generic library_books icon should NOT be used for wiki results
    expect(find.byIcon(Icons.library_books), findsNothing);
  });

  testWidgets('SearchScreen renders map category icon and label badge for map results', (WidgetTester tester) async {
    final mockPois = [
      MapPointOfInterest(
        id: 'stunt_1',
        name: 'Stunt Jump #1',
        category: 'stunts',
        subCategory: 'stunt_jumps',
        gameX: 100,
        gameY: 200,
        description: 'Del Perro Pier ramp',
        isCollectable: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value(mockPois)),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'Stunt'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify sports_motorsports icon is rendered for stunt jumps
    expect(find.byIcon(Icons.sports_motorsports), findsOneWidget);
    expect(find.text('Stunt Jump'), findsOneWidget);
    // Generic location_on icon should NOT be used for styled map results
    expect(find.byIcon(Icons.location_on), findsNothing);
  });

  testWidgets("SearchScreen queries guide articles and renders 'Guides & Tutorials' section", (WidgetTester tester) async {
    const mockGuides = [
      GuideArticle(
        id: 'guide_lester',
        title: 'Lester Assassinations & Stock Market',
        category: 'Money & Stock Market',
        tags: ['Money', 'Stock', 'BAWSAQ'],
        difficulty: 'Intermediate',
        readTimeMinutes: 8,
        contentMarkdown: '# Stock Market\n\nInvest in Betta Pharmaceuticals.',
        videoUrl: 'https://www.youtube.com/watch?v=hG7W5v6J7Z0',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value([])),
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'Lester'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Guides & Tutorials'), findsOneWidget);
    expect(find.text('Lester Assassinations & Stock Market'), findsOneWidget);
    expect(find.text('Map Locations'), findsNothing);
    expect(find.text('Wiki Entries'), findsNothing);
  });

  testWidgets('SearchScreen matches guides by title, category, tags, and contentMarkdown', (WidgetTester tester) async {
    const mockGuides = [
      GuideArticle(
        id: 'guide_1',
        title: 'Lester Assassinations',
        category: 'Money & Stock Market',
        tags: ['BAWSAQ', 'Investment'],
        difficulty: 'Intermediate',
        readTimeMinutes: 8,
        contentMarkdown: '# Overview\n\nSpecial walkthrough mentioning Observation Deck.',
        videoUrl: 'https://www.youtube.com/watch?v=hG7W5v6J7Z0',
      ),
    ];

    // 1. Match by title ("Lester")
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value([])),
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'Lester'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lester Assassinations'), findsOneWidget);

    // 2. Match by category ("Money")
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value([])),
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'Money'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lester Assassinations'), findsOneWidget);

    // 3. Match by tag ("BAWSAQ")
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value([])),
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'BAWSAQ'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lester Assassinations'), findsOneWidget);

    // 4. Match by contentMarkdown ("Observation Deck")
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value([])),
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'Observation Deck'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lester Assassinations'), findsOneWidget);
  });

  testWidgets('Tapping guide result navigates to /guides', (WidgetTester tester) async {
    const mockGuides = [
      GuideArticle(
        id: 'guide_lester',
        title: 'Lester Assassinations & Stock Market',
        category: 'Money & Stock Market',
        tags: ['Money', 'Stock'],
        difficulty: 'Intermediate',
        readTimeMinutes: 8,
        contentMarkdown: '# Stock Market Strategy',
        videoUrl: 'https://www.youtube.com/watch?v=hG7W5v6J7Z0',
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        wikiItemsProvider.overrideWith((ref) => Future.value([])),
        mapPoiProvider.overrideWith((ref) => Future.value([])),
        guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
      ],
    );

    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(query: 'Lester'),
        ),
        GoRoute(
          path: '/guides',
          builder: (context, state) => const Scaffold(body: Text('Guides View')),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on guide item
    await tester.tap(find.text('Lester Assassinations & Stock Market'));
    await tester.pumpAndSettle();

    // Ensure we navigated to /guides
    expect(find.text('Guides View'), findsOneWidget);
  });

  testWidgets('SearchScreen renders guide badges (category, difficulty, read time, video indicator)', (WidgetTester tester) async {
    const mockGuides = [
      GuideArticle(
        id: 'guide_lester',
        title: 'Lester Assassinations & Stock Market',
        category: 'Money & Stock Market',
        tags: ['Money'],
        difficulty: 'Intermediate',
        readTimeMinutes: 8,
        contentMarkdown: '# Stock Strategy\n\nHigh payout guide.',
        videoUrl: 'https://www.youtube.com/watch?v=hG7W5v6J7Z0',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value([])),
          mapPoiProvider.overrideWith((ref) => Future.value([])),
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
        ],
        child: const MaterialApp(
          home: SearchScreen(query: 'Lester'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Category badge
    expect(find.text('Money & Stock Market'), findsOneWidget);

    // Difficulty badge
    expect(find.text('Intermediate'), findsOneWidget);

    // Read time text
    expect(find.text('8 min'), findsOneWidget);

    // Video indicator icon on guide leading
    expect(find.byIcon(Icons.videocam), findsOneWidget);

    // Book icon on guide leading
    expect(find.byIcon(Icons.menu_book), findsOneWidget);

    // Trailing chevron
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}


