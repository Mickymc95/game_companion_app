import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/models/search_result_item.dart';
import 'package:game_companion_sdk/sdk/models/wiki_item.dart';
import 'package:game_companion_sdk/sdk/models/map_poi.dart';
import 'package:game_companion_sdk/ui/screens/search_screen.dart';
import 'package:game_companion_sdk/ui/providers/search_providers.dart';
import 'package:game_companion_sdk/sdk/map/target_map_position_provider.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('SearchScreen empty state', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        unifiedSearchResultsProvider('empty').overrideWith((ref) => Future.value([])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SearchScreen(query: 'empty'),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait for future

    expect(find.text('No results found.'), findsOneWidget);
  });

  testWidgets('SearchScreen search result tapping and routing', (WidgetTester tester) async {
    final mapPoi = MapPointOfInterest(
      id: 'poi1',
      name: 'Burger Shot',
      category: 'Food',
      subCategory: '',
      gameX: 100,
      gameY: 100,
      description: 'Burgers',
    );

    final wikiItem = WikiItem(
      id: 'w1',
      title: 'Adder',
      category: 'Vehicles',
      stats: {},
      description: 'Car',
      thumbnailUrl: '',
    );

    final mockResults = [
      SearchResultItem(
        title: mapPoi.name,
        subtitle: mapPoi.category,
        type: SearchResultType.mapPoi,
        payload: mapPoi,
      ),
      SearchResultItem(
        title: wikiItem.title,
        subtitle: wikiItem.category,
        type: SearchResultType.wikiItem,
        payload: wikiItem,
      ),
    ];

    bool pushedToMap = false;
    bool pushedToWikiDetail = false;
    WikiItem? passedWikiItem;

    final router = GoRouter(
      initialLocation: '/search',
      routes: [
        GoRoute(
          path: '/search',
          builder: (context, state) => const SearchScreen(query: 'test'),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) {
            pushedToMap = true;
            return const Scaffold(body: Text('Map Screen'));
          },
        ),
        GoRoute(
          path: '/wiki/detail',
          builder: (context, state) {
            pushedToWikiDetail = true;
            passedWikiItem = state.extra as WikiItem?;
            return const Scaffold(body: Text('Wiki Detail'));
          },
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        unifiedSearchResultsProvider('test').overrideWith((ref) => Future.value(mockResults)),
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

    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait for future

    expect(find.text('Map Locations'), findsOneWidget);
    expect(find.text('Wiki Entries'), findsOneWidget);
    expect(find.text('Burger Shot'), findsOneWidget);
    expect(find.text('Adder'), findsOneWidget);

    // Tap Map Location
    await tester.tap(find.text('Burger Shot'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(pushedToMap, isTrue);
    expect(find.text('Map Screen'), findsOneWidget);

    final target = container.read(targetMapPositionProvider);
    expect(target, isNotNull);
    expect(target?.poiId, 'poi1');

    // Go back to search to test wiki route
    router.go('/search');
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Tap Wiki Entry
    await tester.tap(find.text('Adder'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(pushedToWikiDetail, isTrue);
    expect(passedWikiItem?.id, 'w1');
    expect(find.text('Wiki Detail'), findsOneWidget);
  });
}
