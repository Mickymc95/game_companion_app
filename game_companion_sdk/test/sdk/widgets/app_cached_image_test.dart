import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_companion_sdk/sdk/widgets/app_cached_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

void main() {
  group('AppCachedImage Widget Tests', () {
    testWidgets('Renders placeholder and CircularProgressIndicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/loading.webp',
            ),
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Applies ClipRRect when borderRadius is provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/image.webp',
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );

      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsOneWidget);

      final clipRRect = tester.widget<ClipRRect>(clipRRectFinder);
      expect(clipRRect.borderRadius, BorderRadius.circular(12));
    });

    testWidgets('Does not apply ClipRRect when borderRadius is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/image.webp',
              borderRadius: null,
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsNothing);
    });

    testWidgets('Does not apply ClipRRect when borderRadius is BorderRadius.zero', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCachedImage(
              imageUrl: 'https://example.com/image.webp',
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsNothing);
    });
  });
}
