import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:game_companion_sdk/sdk/models/guide_article.dart';
import 'package:game_companion_sdk/ui/providers/guides_provider.dart';
import 'package:game_companion_sdk/ui/providers/scroll_providers.dart';
import 'package:game_companion_sdk/ui/screens/guides_tab.dart';
import 'package:game_companion_sdk/ui/widgets/youtube_thumbnail_card.dart';

void main() {
  const mockGuides = [
    GuideArticle(
      id: 'guide_money_lester',
      title: 'Lester Assassinations & Stock Market Investment Strategy',
      category: 'Money & Stock Market',
      tags: ['Money', 'Stock Market', 'Lester', 'BAWSAQ'],
      difficulty: 'Intermediate',
      readTimeMinutes: 8,
      contentMarkdown: '# Lester Stock Market Strategy\n\nMaximizing cash reserves in GTA V Story Mode.\n\n## Key Rules\n- Rule 1: Complete Big Score first\n- Rule 2: Invest 100% of all 3 characters',
      videoUrl: 'https://www.youtube.com/watch?v=MCkgSWeqmPM',
    ),
    GuideArticle(
      id: 'guide_stunts_50',
      title: '50 Stunt Jumps Complete Masterclass',
      category: 'Stunt Jumps',
      tags: ['Stunts', 'Bati 801', 'Ramps'],
      difficulty: 'Advanced',
      readTimeMinutes: 6,
      contentMarkdown: '# 50 Stunt Jumps Masterclass\n\nCinematic camera landing physics.\n\n## Steps\n1. Level the vehicle\n2. Touch down clean',
      videoUrl: 'https://www.youtube.com/watch?v=Q2PvG58TtzM',
    ),
    GuideArticle(
      id: 'guide_secrets_supercars',
      title: 'Guaranteed Free Supercar Spawns',
      category: 'Secrets, Weapons & Rare Vehicles',
      tags: ['Supercars', 'Adder', 'Zentorno'],
      difficulty: 'Beginner',
      readTimeMinutes: 5,
      contentMarkdown: '# Guaranteed Supercar Spawns\n\nFree high performance vehicles in Los Santos.\n\n## Locations\n- Portola Drive Adder\n- Burton multi-story Zentorno',
      videoUrl: null,
    ),
  ];

  testWidgets('GuidesTab renders list of guide cards with title, tags, category badge, difficulty badge, and read time badge', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GuidesTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(GuidesTab), findsOneWidget);

    // Guide titles
    expect(find.text('Lester Assassinations & Stock Market Investment Strategy'), findsOneWidget);
    expect(find.text('50 Stunt Jumps Complete Masterclass'), findsOneWidget);
    expect(find.text('Guaranteed Free Supercar Spawns'), findsOneWidget);

    // Category badges
    expect(find.text('Money & Stock Market'), findsWidgets);
    expect(find.text('Stunt Jumps'), findsWidgets);
    expect(find.text('Secrets, Weapons & Rare Vehicles'), findsWidgets);

    // Difficulty badges
    expect(find.text('Intermediate'), findsWidgets);
    expect(find.text('Advanced'), findsWidgets);
    expect(find.text('Beginner'), findsWidgets);

    // Read time badges
    expect(find.text('8 min'), findsOneWidget);
    expect(find.text('6 min'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);

    // Video indicator badges (only for guides with videoUrl)
    expect(find.text('Video'), findsNWidgets(2));

    // Tags
    expect(find.text('Lester'), findsOneWidget);
    expect(find.text('Bati 801'), findsOneWidget);
    expect(find.text('Adder'), findsOneWidget);
  });

  testWidgets('GuidesTab renders interactive filter chips at top and filtering narrows the card list', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GuidesTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify filter chips exist
    expect(find.widgetWithText(FilterChip, 'All'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Money & Stock Market'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Stunt Jumps'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, '100% Completion'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Aerial & Flight Challenges'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Secrets, Weapons & Rare Vehicles'), findsOneWidget);

    // Tap on 'Stunt Jumps' filter chip
    await tester.tap(find.widgetWithText(FilterChip, 'Stunt Jumps'));
    await tester.pumpAndSettle();

    // Only Stunt Jumps guide should be visible
    expect(find.text('50 Stunt Jumps Complete Masterclass'), findsOneWidget);
    expect(find.text('Lester Assassinations & Stock Market Investment Strategy'), findsNothing);
    expect(find.text('Guaranteed Free Supercar Spawns'), findsNothing);

    // Tap on 'All' filter chip to reset
    await tester.tap(find.widgetWithText(FilterChip, 'All'));
    await tester.pumpAndSettle();

    // All guides should be visible again
    expect(find.text('50 Stunt Jumps Complete Masterclass'), findsOneWidget);
    expect(find.text('Lester Assassinations & Stock Market Investment Strategy'), findsOneWidget);
    expect(find.text('Guaranteed Free Supercar Spawns'), findsOneWidget);
  });

  testWidgets('Guide card expands to display Markdown walk-through and YouTube thumbnail preview card', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GuidesTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on first card to expand the ExpansionTile
    await tester.tap(find.text('Lester Assassinations & Stock Market Investment Strategy'));
    await tester.pumpAndSettle();

    // Markdown content should now be rendered
    expect(find.byType(MarkdownBody), findsOneWidget);
    expect(find.textContaining('Lester Stock Market Strategy'), findsOneWidget);
    expect(find.textContaining('Maximizing cash reserves'), findsOneWidget);

    // YouTube thumbnail card should be rendered
    expect(find.byType(YoutubeThumbnailCard), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.text('Watch on YouTube'), findsOneWidget);
  });

  testWidgets('YoutubeThumbnailCard renders 16:9 aspect ratio, dark offline fallback, and handles tap safely', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: YoutubeThumbnailCard(
            videoUrl: 'https://www.youtube.com/watch?v=MCkgSWeqmPM',
            thumbnailUrl: '', // Trigger offline fallback view
            title: 'Test Lester Video',
          ),
        ),
      ),
    );

    await tester.pump();

    // Aspect ratio 16:9 check
    final aspectRatioFinder = find.byWidgetPredicate(
      (w) => w is AspectRatio && (w.aspectRatio - (16.0 / 9.0)).abs() < 0.01,
    );
    expect(aspectRatioFinder, findsOneWidget);

    // Offline fallback view elements
    expect(find.text('Video Preview'), findsOneWidget);
    expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

    // Red play button overlay
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    // "Watch on YouTube" action button
    expect(find.text('Watch on YouTube'), findsOneWidget);

    // Tap "Watch on YouTube" safely
    await tester.tap(find.text('Watch on YouTube'));
    await tester.pumpAndSettle();
  });

  testWidgets('GuidesTab attaches guidesScrollControllerProvider and supports scroll control', (WidgetTester tester) async {
    final container = ProviderContainer(
      overrides: [
        guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: GuidesTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final controller = container.read(guidesScrollControllerProvider);
    expect(controller.hasClients, isTrue);
  });

  testWidgets('GuidesTab shows empty state when selected category has no matching guides', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          guidesProvider.overrideWith((ref) => Future.value(mockGuides)),
          selectedGuideCategoryProvider.overrideWith((ref) => '100% Completion'),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: GuidesTab(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('No guides found in this category.'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });
}
