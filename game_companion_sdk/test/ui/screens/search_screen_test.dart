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
}
