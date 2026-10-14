import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_companion_sdk/ui/screens/map_tab.dart';
import 'package:game_companion_sdk/sdk/storage/collection_tracker.dart';
import 'package:game_companion_sdk/sdk/map/poi_provider.dart';
import 'package:game_companion_sdk/sdk/models/map_poi.dart';
import 'package:flutter_map/flutter_map.dart';

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

    await tester.pumpAndSettle();

    expect(find.byType(MapTab), findsOneWidget);
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(FilterChip), findsWidgets);
    expect(find.text('All'), findsOneWidget);
  });
}
