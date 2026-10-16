import 'package:game_companion_sdk/sdk/models/map_poi.dart';
import 'package:game_companion_sdk/ui/providers/wiki_providers.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:game_companion_sdk/ui/providers/map_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_companion_sdk/ui/screens/map_tab.dart';
import 'package:game_companion_sdk/sdk/storage/collection_tracker.dart';
import 'package:game_companion_sdk/sdk/map/poi_provider.dart';
import 'package:game_companion_sdk/sdk/map/target_map_position_provider.dart';
import 'package:game_companion_sdk/sdk/map/coords_helper.dart';

void main() {
  testWidgets('MapTab builds and shows filters, layer switcher, and telemetry pill', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: '1',
        name: 'Spaceship Part 1',
        category: 'collectibles',
        subCategory: 'parts',
        gameX: 0,
        gameY: 0,
        description: 'desc',
        isCollectable: true,
      )
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          poiProvider.overrideWith((ref) => Future.value(testPois)),
          mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
        ],
        child: const MaterialApp(
          home: Scaffold(body: MapTab()),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(MapTab), findsOneWidget);
    expect(find.byType(FlutterMap, skipOffstage: false), findsOneWidget);
    expect(find.byType(FilterChip), findsWidgets);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Hide Found'), findsOneWidget);
    expect(find.text('0/1 Found (0%)'), findsOneWidget);
    expect(find.byTooltip('Switch Map Layer'), findsOneWidget);
  });

  testWidgets('MapTab reacts to targetMapPositionProvider', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value([])),
        mapPoiProvider.overrideWith((ref) => Future.value([])),
        wikiItemsProvider.overrideWith((ref) => Future.value([])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: MapTab()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Verify initial state
    expect(find.byType(FlutterMap, skipOffstage: false), findsOneWidget);

    // Set a new target position
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(-500.0, 1200.0),
      zoom: 4.5,
    );

    await tester.pump();

    // After animation/build finishes, the target position should have been reset to null
    final targetPos = container.read(targetMapPositionProvider);
    expect(targetPos, isNull);
  });

  testWidgets('MapTab layer switcher toggles activeMapLayerProvider', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        mapPoiProvider.overrideWith((ref) => Future.value([])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: MapTab()),
        ),
      ),
    );
    await tester.pump();

    expect(container.read(activeMapLayerProvider), MapLayerType.road);

    // Tap layer switcher button
    await tester.tap(find.byTooltip('Switch Map Layer'));
    await tester.pumpAndSettle();

    // Tap Satellite option
    await tester.tap(find.text('Satellite'));
    await tester.pumpAndSettle();

    expect(container.read(activeMapLayerProvider), MapLayerType.satellite);
  });

  testWidgets('MapTab hideCollectedPins removes collected markers from view', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'collected_1': true});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: '1',
        name: 'Part 1',
        category: 'collectibles',
        subCategory: 'parts',
        gameX: 0,
        gameY: 0,
        description: 'desc',
        isCollectable: true,
      ),
      MapPointOfInterest(
        id: '2',
        name: 'Part 2',
        category: 'collectibles',
        subCategory: 'parts',
        gameX: 100,
        gameY: 100,
        description: 'desc',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: MapTab()),
        ),
      ),
    );
    await tester.pump();

    // Telemetry reflects 1 of 2 collected
    expect(find.text('1/2 Found (50%)'), findsOneWidget);

    // Initial state: both markers rendered (one collected with checkmark)
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Toggle 'Hide Found'
    await tester.tap(find.text('Hide Found'));
    await tester.pump();

    // Now the collected marker is omitted
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('MapTab filter sheet displays accordion groups and subcategories', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'sp_1',
        name: 'Spaceship Part 1',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: 0,
        gameY: 0,
        description: 'desc',
        isCollectable: true,
      ),
      MapPointOfInterest(
        id: 'sj_1',
        name: 'Stunt Jump 1',
        category: 'stunts',
        subCategory: 'stunt_jumps',
        gameX: 100,
        gameY: 100,
        description: 'desc',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: MapTab()),
        ),
      ),
    );
    await tester.pump();

    // Open the Filter Sheet
    await tester.tap(find.byIcon(Icons.filter_list));
    await tester.pumpAndSettle();

    // Check Sheet Header and Main Accordion Groups
    expect(find.text('Map Filters & Progress'), findsOneWidget);
    expect(find.text('Select All'), findsOneWidget);
    expect(find.text('Clear All'), findsOneWidget);
    expect(find.text('Collectibles'), findsWidgets);
    expect(find.text('Stunts & Aerial'), findsWidgets);
    expect(find.text('Services'), findsWidgets);
    expect(find.text('Secrets & World'), findsWidgets);

    // Tap Done to close
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
  });

  testWidgets('MapTab displays Stunt Jump specifications in detail sheet', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final stuntJump = MapPointOfInterest(
      id: 'stunt_jump_01',
      name: 'Del Perro Freeway Jump',
      category: 'stunts',
      subCategory: 'stunt_jumps',
      gameX: -1200.0,
      gameY: -800.0,
      description: 'Jump over the barrier onto the freeway',
      isCollectable: true,
      takeoffDirection: 'East-Southeast',
      landingZone: 'Freeway median between lanes',
      vehicleRecommendation: 'Pegassi Bati 801',
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        mapPoiProvider.overrideWith((ref) => Future.value([stuntJump])),
        wikiItemsProvider.overrideWith((ref) => Future.value([])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(body: MapTab()),
        ),
      ),
    );
    await tester.pump();

    // Tap on the Stunt Jump marker
    await tester.tap(find.byIcon(Icons.sports_motorsports));
    await tester.pumpAndSettle();

    // Verify detail sheet shows stunt jump specifications prominently
    expect(find.text('Del Perro Freeway Jump'), findsOneWidget);
    expect(find.text('Stunt Jump Specifications'), findsOneWidget);
    expect(find.textContaining('East-Southeast'), findsOneWidget);
    expect(find.textContaining('Freeway median between lanes'), findsOneWidget);
    expect(find.textContaining('Pegassi Bati 801'), findsOneWidget);

    // Tap Mark as Collected
    await tester.tap(find.text('Mark as Collected'));
    await tester.pumpAndSettle();

    // Verify state updated
    expect(container.read(collectionTrackerProvider).contains('stunt_jump_01'), isTrue);
  });
}
