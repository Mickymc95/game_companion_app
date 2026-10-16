import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_companion_sdk/sdk/models/map_poi.dart';
import 'package:game_companion_sdk/sdk/storage/collection_tracker.dart';
import 'package:game_companion_sdk/ui/providers/map_providers.dart';

void main() {
  group('MapFilterState & MapFilterNotifier', () {
    test('Default state has canonical subcategories enabled', () {
      final notifier = MapFilterNotifier();
      expect(notifier.isSubcategoryEnabled('spaceship_parts'), isTrue);
      expect(notifier.isSubcategoryEnabled('letter_scraps'), isTrue);
      expect(notifier.isSubcategoryEnabled('stunt_jumps'), isTrue);
      expect(notifier.isCategoryFullyEnabled('collectibles'), isTrue);
      expect(notifier.isCategoryPartiallyEnabled('collectibles'), isFalse);
    });

    test('Toggling a single subcategory operates independently', () {
      final notifier = MapFilterNotifier();

      // Toggle off spaceship_parts
      notifier.toggleSubcategory('spaceship_parts');
      expect(notifier.isSubcategoryEnabled('spaceship_parts'), isFalse);
      expect(notifier.isSubcategoryEnabled('letter_scraps'), isTrue);
      expect(notifier.isSubcategoryEnabled('stunt_jumps'), isTrue);

      // Category 'collectibles' should now be partially enabled
      expect(notifier.isCategoryFullyEnabled('collectibles'), isFalse);
      expect(notifier.isCategoryPartiallyEnabled('collectibles'), isTrue);

      // Toggle back on
      notifier.toggleSubcategory('spaceship_parts');
      expect(notifier.isSubcategoryEnabled('spaceship_parts'), isTrue);
      expect(notifier.isCategoryFullyEnabled('collectibles'), isTrue);
    });

    test('Toggling a category group affects only that group', () {
      final notifier = MapFilterNotifier();

      // Disabling stunts group
      notifier.toggleCategoryGroup('stunts');
      expect(notifier.isSubcategoryEnabled('stunt_jumps'), isFalse);
      expect(notifier.isSubcategoryEnabled('under_the_bridge'), isFalse);
      expect(notifier.isSubcategoryEnabled('knife_flights'), isFalse);

      // Collectibles remain enabled
      expect(notifier.isSubcategoryEnabled('spaceship_parts'), isTrue);
      expect(notifier.isSubcategoryEnabled('letter_scraps'), isTrue);
      expect(notifier.isCategoryFullyEnabled('collectibles'), isTrue);

      // Re-enabling stunts group
      notifier.toggleCategoryGroup('stunts');
      expect(notifier.isSubcategoryEnabled('stunt_jumps'), isTrue);
      expect(notifier.isSubcategoryEnabled('under_the_bridge'), isTrue);
      expect(notifier.isSubcategoryEnabled('knife_flights'), isTrue);
      expect(notifier.isCategoryFullyEnabled('stunts'), isTrue);
    });

    test('enableAll and disableAll work across all subcategories', () {
      final notifier = MapFilterNotifier();

      notifier.disableAll();
      expect(notifier.isSubcategoryEnabled('spaceship_parts'), isFalse);
      expect(notifier.isSubcategoryEnabled('stunt_jumps'), isFalse);
      expect(notifier.isCategoryFullyEnabled('collectibles'), isFalse);
      expect(notifier.isCategoryPartiallyEnabled('collectibles'), isFalse);

      notifier.enableAll();
      expect(notifier.isSubcategoryEnabled('spaceship_parts'), isTrue);
      expect(notifier.isSubcategoryEnabled('stunt_jumps'), isTrue);
      expect(notifier.isCategoryFullyEnabled('collectibles'), isTrue);
    });
  });

  group('Completion Statistics Models', () {
    test('SubcategoryCompletionStats computes remaining and percentage accurately', () {
      const stats = SubcategoryCompletionStats(
        subCategory: 'stunt_jumps',
        displayName: 'Stunt Jumps',
        totalCount: 50,
        collectedCount: 20,
        isCollectable: true,
      );

      expect(stats.remainingCount, 30);
      expect(stats.percentage, 0.4);
      expect(stats.isCollectable, isTrue);
    });

    test('SubcategoryCompletionStats handles 0 total without division error', () {
      const stats = SubcategoryCompletionStats(
        subCategory: 'empty_sub',
        displayName: 'Empty',
        totalCount: 0,
        collectedCount: 0,
        isCollectable: false,
      );

      expect(stats.remainingCount, 0);
      expect(stats.percentage, 0.0);
    });

    test('CategoryCompletionStats exposes subcategoryStats and computes remaining count', () {
      const sub1 = SubcategoryCompletionStats(
        subCategory: 'sub1',
        displayName: 'Sub 1',
        totalCount: 10,
        collectedCount: 5,
        isCollectable: true,
      );
      const sub2 = SubcategoryCompletionStats(
        subCategory: 'sub2',
        displayName: 'Sub 2',
        totalCount: 15,
        collectedCount: 10,
        isCollectable: true,
      );

      const cat = CategoryCompletionStats(
        category: 'collectibles',
        displayName: 'Collectibles',
        totalCount: 25,
        collectedCount: 15,
        subcategoryStats: [sub1, sub2],
      );

      expect(cat.remainingCount, 10);
      expect(cat.percentage, 15 / 25);
      expect(cat.subcategoryStats.length, 2);
    });
  });

  group('mapCompletionSummaryProvider Reactive Calculation', () {
    test('Computes aggregate and subcategory telemetry correctly', () async {
      SharedPreferences.setMockInitialValues({'collected_sj_1': true, 'collected_sp_1': true});
      final prefs = await SharedPreferences.getInstance();

      final pois = [
        MapPointOfInterest(
          id: 'sj_1',
          name: 'Stunt Jump 1',
          category: 'stunts',
          subCategory: 'stunt_jumps',
          gameX: 100,
          gameY: 200,
          description: 'Jump 1',
          isCollectable: true,
        ),
        MapPointOfInterest(
          id: 'sj_2',
          name: 'Stunt Jump 2',
          category: 'stunts',
          subCategory: 'stunt_jumps',
          gameX: 150,
          gameY: 250,
          description: 'Jump 2',
          isCollectable: true,
        ),
        MapPointOfInterest(
          id: 'utb_1',
          name: 'Bridge 1',
          category: 'stunts',
          subCategory: 'under_the_bridge',
          gameX: 300,
          gameY: 400,
          description: 'Bridge 1',
          isCollectable: false,
        ),
        MapPointOfInterest(
          id: 'sp_1',
          name: 'Spaceship 1',
          category: 'collectibles',
          subCategory: 'spaceship_parts',
          gameX: 500,
          gameY: 600,
          description: 'Part 1',
          isCollectable: true,
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          mapPoiProvider.overrideWith((ref) => Future.value(pois)),
        ],
      );

      // Wait for provider to load
      await container.read(mapPoiProvider.future);

      final summary = container.read(mapCompletionSummaryProvider);

      // Total collectables: sj_1, sj_2, sp_1 = 3 collectables
      expect(summary.totalCount, 3);
      // Collected: sj_1, sp_1 = 2 collected
      expect(summary.collectedCount, 2);
      expect(summary.remainingCount, 1);
      expect(summary.percentage, 2 / 3);

      // Check stunts category stats
      final stuntsCat = summary.categoryStats.firstWhere((c) => c.category == 'stunts');
      expect(stuntsCat.totalCount, 2); // only stunt jumps are collectable
      expect(stuntsCat.collectedCount, 1);

      final sjStat = stuntsCat.subcategoryStats.firstWhere((s) => s.subCategory == 'stunt_jumps');
      expect(sjStat.totalCount, 2);
      expect(sjStat.collectedCount, 1);
      expect(sjStat.remainingCount, 1);
      expect(sjStat.isCollectable, isTrue);

      final utbStat = stuntsCat.subcategoryStats.firstWhere((s) => s.subCategory == 'under_the_bridge');
      expect(utbStat.totalCount, 1);
      expect(utbStat.collectedCount, 0);
      expect(utbStat.isCollectable, isFalse);
    });
  });
}
