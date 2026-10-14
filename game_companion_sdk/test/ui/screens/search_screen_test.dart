import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/ui/screens/search_screen.dart';

void main() {
  testWidgets('SearchScreen queries both POI and Wiki items correctly', (WidgetTester tester) async {
    // We mock the environment so that we can test SearchScreen in isolation
    await tester.pumpWidget(
      const MaterialApp(
        home: SearchScreen(query: 'Carbine'),
      ),
    );

    await tester.pumpAndSettle();

    // "Carbine" should match a Wiki item (Carbine Rifle) but not POIs
    expect(find.text('Wiki Entries'), findsOneWidget);
    expect(find.text('Carbine Rifle'), findsOneWidget);
    expect(find.text('Map Locations'), findsNothing);

    // Let's test another query
    await tester.pumpWidget(
      const MaterialApp(
        home: SearchScreen(query: 'Spaceship'),
      ),
    );

    await tester.pumpAndSettle();

    // "Spaceship" should match a POI but not Wiki
    expect(find.text('Map Locations'), findsOneWidget);
    expect(find.text('Spaceship Part #1'), findsOneWidget);
    expect(find.text('Wiki Entries'), findsNothing);
  });
}
