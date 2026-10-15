import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/models/wiki_item.dart';
import 'package:game_companion_sdk/ui/providers/wiki_providers.dart';
import 'package:game_companion_sdk/ui/screens/wiki_tab.dart';
import 'package:game_companion_sdk/ui/screens/wiki_detail_screen.dart';
import 'package:game_companion_sdk/ui/providers/map_providers.dart';

void main() {
  testWidgets('WikiTab renders list of items', (WidgetTester tester) async {
    final mockItems = [
      WikiItem(
        id: '1',
        title: 'Item 1',
        category: 'Weapons',
        stats: {},
        description: 'Desc 1',
        thumbnailUrl: '', // blank handles bad network without image caching errors
      ),
      WikiItem(
        id: '2',
        title: 'Item 2',
        category: 'Vehicles',
        stats: {},
        description: 'Desc 2',
        thumbnailUrl: '',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wikiItemsProvider.overrideWith((ref) => Future.value(mockItems)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: WikiTab(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Weapons'), findsNWidgets(2));
    expect(find.text('Vehicles'), findsNWidgets(2));
  });

  testWidgets('WikiDetailScreen renders stats and linear progress indicator', (WidgetTester tester) async {
    final item = WikiItem(
      id: '1',
      title: 'Adder',
      category: 'Vehicles',
      stats: {
        'Speed': 0.85,
      },
      description: 'A very fast supercar.',
      thumbnailUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapPoiProvider.overrideWith((ref) => Future.value([])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: WikiDetailScreen(item: item),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Adder'), findsOneWidget);
    expect(find.text('Speed'), findsOneWidget);
    expect(find.text('85%'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
