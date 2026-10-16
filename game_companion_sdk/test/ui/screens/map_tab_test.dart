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

  testWidgets('MapTab triggers marker shake animation for targeted POI and automatically opens info card upon completion', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'target_poi_1',
        name: 'Target Spaceship Part',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: 200,
        gameY: 300,
        description: 'Specific part found in alley',
        isCollectable: true,
      ),
      MapPointOfInterest(
        id: 'other_poi_2',
        name: 'Other Letter Scrap',
        category: 'collectibles',
        subCategory: 'letter_scraps',
        gameX: 500,
        gameY: 600,
        description: 'Other item desc',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
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

    // Verify baseline: markers are rendered and no shake animation is running
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_1')), findsNothing);
    expect(find.byKey(const Key('shaking_marker_icon_other_poi_2')), findsNothing);
    expect(find.text('Target Spaceship Part'), findsNothing);

    // Simulate search result selection targeting 'target_poi_1'
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(200, 300),
      zoom: 4.5,
      poiId: 'target_poi_1',
      shakeAndOpenCard: true,
    );

    // Pump to process targetMapPositionProvider listener
    await tester.pump();

    // Provider should have been reset to null
    expect(container.read(targetMapPositionProvider), isNull);

    // Targeted marker icon must now be actively shaking
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_1')), findsOneWidget);
    // Non-targeted marker must NOT be shaking
    expect(find.byKey(const Key('shaking_marker_icon_other_poi_2')), findsNothing);

    // Midway through shake (500ms): target marker is still shaking
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_1')), findsOneWidget);
    expect(find.byKey(const Key('shaking_marker_icon_other_poi_2')), findsNothing);

    // Finish remaining shake duration (600ms, total 1100ms)
    await tester.pump(const Duration(milliseconds: 600));

    // Shake animation is now finished
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_1')), findsNothing);

    // Pump and settle to let bottom sheet info card complete entrance transition
    await tester.pumpAndSettle();

    // Info card for the targeted POI should now be open automatically
    expect(find.text('Target Spaceship Part'), findsOneWidget);
    expect(find.text('Specific part found in alley'), findsOneWidget);
  });

  testWidgets('MapTab manual marker tap opens info card directly without shake animation', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'manual_poi',
        name: 'Manual Tap POI',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: 100,
        gameY: 100,
        description: 'Tapped manually on map',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
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

    // Tap marker directly on map
    await tester.tap(find.byKey(const Key('map_marker_manual_poi')));
    await tester.pumpAndSettle();

    // Info card opens directly
    expect(find.text('Manual Tap POI'), findsOneWidget);
    // No shake animation was triggered
    expect(find.byKey(const Key('shaking_marker_icon_manual_poi')), findsNothing);
  });

  testWidgets('MapTab navigation without POI selection moves map without shake or card', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'poi_nopoi',
        name: 'Unselected POI',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: 100,
        gameY: 100,
        description: 'desc',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
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

    // Navigate to coordinate without POI
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(100, 100),
      zoom: 4.5,
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    // No modal info card opened
    expect(find.text('Unselected POI'), findsNothing);
    expect(find.byKey(const Key('shaking_marker_icon_poi_nopoi')), findsNothing);
  });

  testWidgets('MapTab manual tap on another marker during shake animation cancels shake and opens tapped marker without opening target POI card', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'target_poi_1',
        name: 'Target Spaceship Part',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: 200,
        gameY: 300,
        description: 'Specific part found in alley',
        isCollectable: true,
      ),
      MapPointOfInterest(
        id: 'other_poi_2',
        name: 'Other Letter Scrap',
        category: 'collectibles',
        subCategory: 'letter_scraps',
        gameX: 500,
        gameY: 600,
        description: 'Other item desc',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
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

    // Trigger target shake on target_poi_1
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(200, 300),
      zoom: 4.5,
      poiId: 'target_poi_1',
      shakeAndOpenCard: true,
    );
    await tester.pump();

    // Target marker is shaking
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_1')), findsOneWidget);

    // Advance 400ms into shake
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_1')), findsOneWidget);

    // While shaking, user manually taps other_poi_2
    await tester.tap(find.byKey(const Key('map_marker_other_poi_2')));
    await tester.pump();

    // Shake must be immediately cancelled
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_1')), findsNothing);

    await tester.pumpAndSettle();

    // Tapped marker info card is open
    expect(find.text('Other Letter Scrap'), findsOneWidget);
    // Original target card must NOT be open
    expect(find.text('Target Spaceship Part'), findsNothing);

    // Advance further past the original 1000ms animation duration
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // Target card STILL must not open
    expect(find.text('Target Spaceship Part'), findsNothing);
    expect(find.text('Other Letter Scrap'), findsOneWidget);
  });

  testWidgets('MapTab manual tap on shaking target marker opens info card cleanly once', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'target_poi_1',
        name: 'Target Spaceship Part',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: 200,
        gameY: 300,
        description: 'Specific part found in alley',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
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

    // Trigger target shake
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(200, 300),
      zoom: 4.5,
      poiId: 'target_poi_1',
      shakeAndOpenCard: true,
    );
    await tester.pump();

    // Marker is shaking
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_1')), findsOneWidget);

    // Tap the target marker directly while shaking
    await tester.tap(find.byKey(const Key('map_marker_target_poi_1')));
    await tester.pump();

    // Shake cancelled
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_1')), findsNothing);

    await tester.pumpAndSettle();
    expect(find.text('Target Spaceship Part'), findsOneWidget);

    // Dismiss bottom sheet
    Navigator.of(tester.element(find.text('Target Spaceship Part'))).pop();
    await tester.pumpAndSettle();

    // Card should be dismissed completely (not duplicated underneath)
    expect(find.text('Target Spaceship Part'), findsNothing);

    // Advance past original shake time to ensure no secondary trigger fires
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();
    expect(find.text('Target Spaceship Part'), findsNothing);
  });

  testWidgets('MapTab rapid successive targetMapPosition updates cancel prior shake and target latest POI', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'poi_first',
        name: 'First Target',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: 200,
        gameY: 300,
        description: 'First desc',
        isCollectable: true,
      ),
      MapPointOfInterest(
        id: 'poi_second',
        name: 'Second Target',
        category: 'collectibles',
        subCategory: 'letter_scraps',
        gameX: 400,
        gameY: 500,
        description: 'Second desc',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
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

    // Trigger target 1
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(200, 300),
      zoom: 4.5,
      poiId: 'poi_first',
      shakeAndOpenCard: true,
    );
    await tester.pump();
    expect(find.byKey(const Key('shaking_marker_icon_poi_first')), findsOneWidget);

    // Advance 200ms
    await tester.pump(const Duration(milliseconds: 200));

    // Rapidly trigger target 2
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(400, 500),
      zoom: 4.5,
      poiId: 'poi_second',
      shakeAndOpenCard: true,
    );
    await tester.pump();

    // First shake cancelled, second shake active
    expect(find.byKey(const Key('shaking_marker_icon_poi_first')), findsNothing);
    expect(find.byKey(const Key('shaking_marker_icon_poi_second')), findsOneWidget);

    // Finish remaining second shake duration (1100ms)
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pumpAndSettle();

    // Second target card opened
    expect(find.text('Second Target'), findsOneWidget);
    // First target card NEVER opened
    expect(find.text('First Target'), findsNothing);
  });

  testWidgets('MapTab shake animation cancels and does not open info card when tab becomes inactive (TickerMode false)', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'target_poi_inactive',
        name: 'Inactive Tab Target',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: 200,
        gameY: 300,
        description: 'Should not open over other tab',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
        wikiItemsProvider.overrideWith((ref) => Future.value([])),
      ],
    );

    bool tabActive = true;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TickerMode(
                  enabled: tabActive,
                  child: const MapTab(),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    // Trigger target shake
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(200, 300),
      zoom: 4.5,
      poiId: 'target_poi_inactive',
      shakeAndOpenCard: true,
    );
    await tester.pump();
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_inactive')), findsOneWidget);

    // Advance 300ms
    await tester.pump(const Duration(milliseconds: 300));

    // Simulate user switching away from map tab (TickerMode becomes false in IndexedStack)
    tabActive = false;
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: TickerMode(
              enabled: false,
              child: const MapTab(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Advance past remaining shake duration
    await tester.pump(const Duration(milliseconds: 1200));
    await tester.pumpAndSettle();

    // Info card must NEVER open because map tab was inactive
    expect(find.text('Inactive Tab Target'), findsNothing);
  });

  testWidgets('MapTab opening category filter sheet cancels active shake without ghost modal', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'target_poi_filter',
        name: 'Target Before Filter',
        category: 'collectibles',
        subCategory: 'spaceship_parts',
        gameX: 200,
        gameY: 300,
        description: 'Interrupted by filter FAB',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
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

    // Trigger target shake
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(200, 300),
      zoom: 4.5,
      poiId: 'target_poi_filter',
      shakeAndOpenCard: true,
    );
    await tester.pump();
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_filter')), findsOneWidget);

    // Tap category filter FAB during active shake
    await tester.tap(find.byKey(const Key('map_category_filter')));
    await tester.pump();

    // Shake must be immediately cancelled
    expect(find.byKey(const Key('shaking_marker_icon_target_poi_filter')), findsNothing);

    await tester.pumpAndSettle();

    // Filter sheet is open
    expect(find.text('Map Filters'), findsOneWidget);

    // Advance past shake duration
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Target POI card must NOT open over the filter sheet
    expect(find.text('Target Before Filter'), findsNothing);
    expect(find.text('Map Filters'), findsOneWidget);
  });

  testWidgets('MapTab targeted marker displays original map item icon instead of target symbol', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'property_cinema_doppler',
        name: 'Cinema Doppler',
        category: 'services',
        subCategory: 'properties',
        gameX: 312.4,
        gameY: 184.2,
        description: 'Historic cinema venue located on Vinewood Boulevard',
        isCollectable: false,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
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

    // Trigger target navigation from search
    container.read(targetMapPositionProvider.notifier).state = TargetMapPosition(
      position: inGameToMapCoords(312.4, 184.2),
      zoom: 4.5,
      poiId: 'property_cinema_doppler',
      shakeAndOpenCard: true,
    );
    await tester.pump();

    // Must show original property/cinema icon (Icons.apartment), NOT target symbol (Icons.my_location)
    expect(find.byIcon(Icons.apartment), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsNothing);

    // After animation completes
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pumpAndSettle();

    // Info card opened and original icon remains, never replaced by target symbol
    expect(find.text('Cinema Doppler'), findsOneWidget);
    expect(find.byIcon(Icons.my_location), findsNothing);
  });

  testWidgets('Find Next Closest displays floating SnackBar and tapping View successfully opens nearest POI details', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: 'sub_piece_1',
        name: 'Submarine Piece #01',
        category: 'collectibles',
        subCategory: 'submarine_pieces',
        gameX: -100.0,
        gameY: 200.0,
        description: 'First piece in Paleto Bay',
        isCollectable: true,
      ),
      MapPointOfInterest(
        id: 'sub_piece_2',
        name: 'Submarine Piece #02 - Paleto Cove',
        category: 'collectibles',
        subCategory: 'submarine_pieces',
        gameX: -150.0,
        gameY: 250.0,
        description: 'Paleto Cove Propeller Assembly',
        isCollectable: true,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        poiProvider.overrideWith((ref) => Future.value(testPois)),
        mapPoiProvider.overrideWith((ref) => Future.value(testPois)),
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

    // Tap first marker to open its info card
    await tester.tap(find.byKey(const Key('map_marker_sub_piece_1')));
    await tester.pumpAndSettle();

    // First POI details sheet is open
    expect(find.text('Submarine Piece #01'), findsOneWidget);
    expect(find.text('Find Next Closest'), findsOneWidget);

    // Tap 'Find Next Closest'
    await tester.tap(find.text('Find Next Closest'));
    await tester.pumpAndSettle();

    // The first bottom sheet should now be closed
    expect(find.text('First piece in Paleto Bay'), findsNothing);

    // Floating SnackBar must be displayed with 'View' action
    expect(find.text('Submarine Piece #02 - Paleto Cove'), findsOneWidget);
    expect(find.text('View'), findsOneWidget);
    final snackBarFinder = find.byType(SnackBar);
    expect(snackBarFinder, findsOneWidget);
    final snackBar = tester.widget<SnackBar>(snackBarFinder);
    expect(snackBar.behavior, SnackBarBehavior.floating);

    // Tap 'View' on the SnackBar
    await tester.tap(find.text('View'));
    await tester.pumpAndSettle();

    // The nearest POI details sheet must now be open!
    expect(find.text('Submarine Piece #02 - Paleto Cove'), findsOneWidget);
    expect(find.text('Paleto Cove Propeller Assembly'), findsOneWidget);
  });
}
