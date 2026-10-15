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
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('MapTab builds and shows filters and map', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final testPois = [
      MapPointOfInterest(
        id: '1',
        name: 'Test',
        category: 'collectibles',
        subCategory: 'parts',
        gameX: 0,
        gameY: 0,
        description: 'desc',
      )
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          poiProvider.overrideWith((ref) => Future.value(testPois)),
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
                wikiItemsProvider.overrideWith((ref) => Future.value([])),

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
      position: const LatLng(100.0, 100.0),
      zoom: 3.5,
    );

    await tester.pump();

    // After animation/build finishes, the target position should have been reset to null
    final targetPos = container.read(targetMapPositionProvider);
    expect(targetPos, isNull);
  });
}
