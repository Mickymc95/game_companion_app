import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:game_companion_sdk/sdk/models/wiki_item.dart';
import 'package:game_companion_sdk/ui/screens/wiki_detail_screen.dart';

void main() {
  testWidgets('WikiDetailScreen displays item details and back button, and pops on back button tap', (WidgetTester tester) async {
    final mockItem = WikiItem(
      id: 'item_1',
      title: 'Mock Pistol',
      description: 'A reliable mock pistol.',
      category: 'Weapons',
      thumbnailUrl: 'https://example.com/mock.png',
      stats: {
        'Damage': 0.8,
        'Fire Rate': 0.5,
      },
    );

    bool didPop = false;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => context.push('/wiki/detail'),
                child: const Text('Push'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/wiki/detail',
          builder: (context, state) => WikiDetailScreen(item: mockItem),
        ),
      ],
      observers: [
        _MockNavigatorObserver(onPop: () => didPop = true),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );

    // Initial pump
    await tester.pumpAndSettle();

    // Push the screen
    await tester.tap(find.text('Push'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300)); // wait for transition
    // The CachedNetworkImage may still be spinning, pump And Settle may hang, so we just pump a bit more.
    await tester.pump(const Duration(milliseconds: 300));

    // Verify item details are displayed
    expect(find.text('Mock Pistol'), findsOneWidget);
    expect(find.text('A reliable mock pistol.'), findsOneWidget);
    expect(find.text('Weapons'), findsOneWidget);
    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Damage'), findsOneWidget);
    expect(find.text('80%'), findsOneWidget);
    expect(find.text('Fire Rate'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);

    // Verify back button is visible
    final backButtonFinder = find.byTooltip('Back');
    expect(backButtonFinder, findsOneWidget);

    // Tap back button
    await tester.tap(backButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000)); // wait for full route transition to complete

    // Verify navigation pop occurred
    expect(didPop, isTrue);
    expect(find.text('Mock Pistol'), findsNothing); // Should be back on the initial screen
  });
}

class _MockNavigatorObserver extends NavigatorObserver {
  final VoidCallback onPop;

  _MockNavigatorObserver({required this.onPop});

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    onPop();
  }
}
