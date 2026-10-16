import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_companion_sdk/ui/screens/splash_screen.dart';
import 'package:game_companion_sdk/ui/providers/map_providers.dart';
import 'package:game_companion_sdk/sdk/models/map_poi.dart';

void main() {
  testWidgets('SplashScreen renders animated icon, title, subtitle, and progress bar', (tester) async {
    final mockPois = <MapPointOfInterest>[];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapPoiProvider.overrideWith((ref) => Future.value(mockPois)),
        ],
        child: const MaterialApp(
          home: SplashScreen(),
        ),
      ),
    );

    // Initial frame
    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('GAMES COMPANION'), findsOneWidget);
    expect(find.text('Interactive Map • Wikis • 100% Tracking'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Tap anywhere to skip'), findsOneWidget);

    // Fast forward animation
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 800));
  });
}

