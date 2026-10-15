import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/models/wiki_item.dart';
import 'package:game_companion_sdk/ui/providers/wiki_providers.dart';
import 'package:game_companion_sdk/ui/screens/search_screen.dart';

void main() {
  testWidgets('SearchScreen queries both POI and Wiki items correctly', (WidgetTester tester) async {
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
}
