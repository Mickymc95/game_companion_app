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
}
