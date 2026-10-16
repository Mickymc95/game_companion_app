import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sdk/models/map_poi.dart';
import '../../sdk/storage/collection_tracker.dart';

/// Available map raster layers for GTA V with matching ocean background colors.
enum MapLayerType {
  road(
    displayName: 'Road',
    urlTemplate: 'https://gta5-map.github.io/tiles/road/{z}-{x}_{y}.png',
    backgroundColor: Color(0xFF1862AD),
    icon: Icons.map,
  ),
  satellite(
    displayName: 'Satellite',
    urlTemplate: 'https://gta5-map.github.io/tiles/satellite/{z}-{x}_{y}.png',
    backgroundColor: Color(0xFF143D6B),
    icon: Icons.satellite_alt,
  ),
  atlas(
    displayName: 'Atlas',
    urlTemplate: 'https://gta5-map.github.io/tiles/atlas/{z}-{x}_{y}.png',
    backgroundColor: Color(0xFF0FA8D2),
    icon: Icons.terrain,
  );

  final String displayName;
  final String urlTemplate;
  final Color backgroundColor;
  final IconData icon;

  const MapLayerType({
    required this.displayName,
    required this.urlTemplate,
    required this.backgroundColor,
    required this.icon,
  });
}

/// Active map layer type (defaults to Road)
final activeMapLayerProvider = StateProvider<MapLayerType>((ref) => MapLayerType.road);

/// Legacy provider for backwards compatibility
final isRoadLayerProvider = StateProvider<bool>((ref) {
  return ref.watch(activeMapLayerProvider) == MapLayerType.road;
});

/// Controls whether collected/completed POIs are completely hidden from the map
final hideCollectedPinsProvider = StateProvider<bool>((ref) => false);

/// Holds a currently targeted or highlighted POI (e.g. found via Nearest Neighbor routing)
final highlightedPoiProvider = StateProvider<MapPointOfInterest?>((ref) => null);

/// FutureProvider to load the points of interest from the JSON asset
final mapPoiProvider = FutureProvider<List<MapPointOfInterest>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/data/gtav_map_pois.json');
  final List<dynamic> jsonList = json.decode(jsonString);

  return jsonList.map((json) => MapPointOfInterest.fromJson(json)).toList();
});

/// Provides all unique categories from the loaded POIs
final mapCategoriesProvider = Provider<List<String>>((ref) {
  final pois = ref.watch(mapPoiProvider).valueOrNull ?? [];
  return pois.map((poi) => poi.category).toSet().toList();
});

/// Returns a human-friendly display name for category keys.
String getCategoryDisplayName(String category) {
  switch (category) {
    case 'collectibles':
      return 'Collectibles';
    case 'stunts':
      return 'Stunts & Aerial';
    case 'services':
      return 'Services';
    case 'secrets_world':
      return 'Secrets & World';
    default:
      if (category.isEmpty) return '';
      return category[0].toUpperCase() + category.substring(1).replaceAll('_', ' ');
  }
}

/// Returns a human-friendly display name for subcategory keys.
String getSubcategoryDisplayName(String subCategory) {
  switch (subCategory) {
    case 'spaceship_parts':
      return 'Spaceship Parts';
    case 'letter_scraps':
      return 'Letter Scraps';
    case 'submarine_pieces':
      return 'Submarine Pieces';
    case 'nuclear_waste':
      return 'Nuclear Waste';
    case 'peyote_plants':
      return 'Peyote Plants';
    case 'stunt_jumps':
      return 'Stunt Jumps';
    case 'under_the_bridge':
      return 'Under the Bridge';
    case 'knife_flights':
      return 'Knife Flights';
    case 'properties':
      return 'Safehouses & Properties';
    case 'safehouses':
      return 'Safehouses';
    case 'ammunation':
      return 'Ammu-Nation';
    case 'secrets_easter_eggs':
    case 'easter_eggs':
      return 'Secrets & Easter Eggs';
    case 'vehicle_spawns':
      return 'Rare Vehicle Spawns';
    case 'encounters':
      return 'Encounters & Pickups';
    default:
      if (subCategory.isEmpty) return '';
      return subCategory
          .split('_')
          .map((word) => word.isNotEmpty ? word[0].toUpperCase() + word.substring(1) : '')
          .join(' ');
  }
}

/// Immutable state containing the set of active, enabled subcategories.
@immutable
class MapFilterState {
  final Set<String> enabledSubcategories;

  const MapFilterState({required this.enabledSubcategories});

  /// Canonical mapping of top-level categories to their member subcategories.
  static const Map<String, List<String>> categorySubcategories = {
    'collectibles': [
      'spaceship_parts',
      'letter_scraps',
      'submarine_pieces',
      'nuclear_waste',
      'peyote_plants',
    ],
    'stunts': [
      'stunt_jumps',
      'under_the_bridge',
      'knife_flights',
    ],
    'services': [
      'properties',
      'safehouses',
      'ammunation',
    ],
    'secrets_world': [
      'secrets_easter_eggs',
      'vehicle_spawns',
      'encounters',
    ],
  };

  /// Set of all default subcategories enabled out-of-the-box.
  static const Set<String> allDefaultSubcategories = {
    'spaceship_parts',
    'letter_scraps',
    'submarine_pieces',
    'nuclear_waste',
    'peyote_plants',
    'stunt_jumps',
    'under_the_bridge',
    'knife_flights',
    'properties',
    'safehouses',
    'ammunation',
    'secrets_easter_eggs',
    'vehicle_spawns',
    'encounters',
    'parts', // Compatibility fixture
  };

  /// Returns the subcategories belonging to a category.
  static List<String> getSubcategoriesForCategory(String category) {
    return categorySubcategories[category] ?? [category];
  }

  /// Whether a specific subcategory is currently enabled.
  bool isSubcategoryEnabled(String subCategory) {
    return enabledSubcategories.contains(subCategory);
  }

  /// Whether all subcategories in a category group are enabled.
  bool isCategoryFullyEnabled(dynamic categoryOrSubcategories) {
    final Iterable<String> subcats = categoryOrSubcategories is String
        ? getSubcategoriesForCategory(categoryOrSubcategories)
        : (categoryOrSubcategories as Iterable<String>);
    if (subcats.isEmpty) return false;
    return subcats.every(enabledSubcategories.contains);
  }

  /// Whether some, but not all, subcategories in a category group are enabled.
  bool isCategoryPartiallyEnabled(dynamic categoryOrSubcategories) {
    final Iterable<String> subcats = categoryOrSubcategories is String
        ? getSubcategoriesForCategory(categoryOrSubcategories)
        : (categoryOrSubcategories as Iterable<String>);
    if (subcats.isEmpty) return false;
    final enabledCount = subcats.where(enabledSubcategories.contains).length;
    return enabledCount > 0 && enabledCount < subcats.length;
  }

  /// Helper to toggle subcategory and return a new state.
  MapFilterState toggleSubcategory(String subCategory) {
    final current = Set<String>.from(enabledSubcategories);
    if (current.contains(subCategory)) {
      current.remove(subCategory);
    } else {
      current.add(subCategory);
    }
    return MapFilterState(enabledSubcategories: current);
  }

  /// Helper to ensure a specific subcategory is enabled.
  MapFilterState enableSubcategory(String subCategory) {
    if (enabledSubcategories.contains(subCategory)) return this;
    final current = Set<String>.from(enabledSubcategories)..add(subCategory);
    return MapFilterState(enabledSubcategories: current);
  }

  /// Helper to toggle category group and return a new state.
  MapFilterState toggleCategoryGroup(dynamic categoryOrSubcategories) {
    final Iterable<String> subcats = categoryOrSubcategories is String
        ? getSubcategoriesForCategory(categoryOrSubcategories)
        : (categoryOrSubcategories as Iterable<String>);
    final current = Set<String>.from(enabledSubcategories);
    final allEnabled = subcats.isNotEmpty && subcats.every(current.contains);

    if (allEnabled) {
      current.removeAll(subcats);
    } else {
      current.addAll(subcats);
    }
    return MapFilterState(enabledSubcategories: current);
  }

  /// Helper to enable all subcategories.
  MapFilterState enableAll([Iterable<String>? subcategories]) {
    final target = subcategories != null
        ? subcategories.toSet()
        : allDefaultSubcategories;
    return MapFilterState(enabledSubcategories: target);
  }

  /// Helper to disable all subcategories.
  MapFilterState disableAll() {
    return const MapFilterState(enabledSubcategories: {});
  }

  /// Backwards-compatibility helper for legacy callers expecting `filterState.contains(key)`.
  bool contains(String categoryOrSubcategory) {
    if (enabledSubcategories.contains(categoryOrSubcategory)) return true;
    if (categorySubcategories.containsKey(categoryOrSubcategory)) {
      return isCategoryFullyEnabled(categoryOrSubcategory);
    }
    return false;
  }

  MapFilterState copyWith({Set<String>? enabledSubcategories}) {
    return MapFilterState(
      enabledSubcategories: enabledSubcategories ?? this.enabledSubcategories,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MapFilterState &&
          other.enabledSubcategories.length == enabledSubcategories.length &&
          other.enabledSubcategories.containsAll(enabledSubcategories);

  @override
  int get hashCode => enabledSubcategories.fold(0, (prev, elem) => prev ^ elem.hashCode);
}

/// Notifier to manage the set of actively selected/filtered subcategories and categories
class MapFilterNotifier extends StateNotifier<MapFilterState> {
  bool _isInitialized = false;

  MapFilterNotifier([Set<String>? initialSubcategories])
      : super(MapFilterState(
          enabledSubcategories: initialSubcategories ?? MapFilterState.allDefaultSubcategories,
        ));

  /// Checks if a subcategory is enabled.
  bool isSubcategoryEnabled(String subCategory) => state.isSubcategoryEnabled(subCategory);

  /// Checks if all subcategories in a category are enabled.
  bool isCategoryFullyEnabled(dynamic category) => state.isCategoryFullyEnabled(category);

  /// Checks if a category is partially enabled.
  bool isCategoryPartiallyEnabled(dynamic category) => state.isCategoryPartiallyEnabled(category);

  /// Toggles an individual subcategory on or off.
  void toggleSubcategory(String subCategory) {
    state = state.toggleSubcategory(subCategory);
  }

  /// Ensures an individual subcategory is enabled.
  void enableSubcategory(String subCategory) {
    state = state.enableSubcategory(subCategory);
  }

  /// Toggles an entire category group on or off.
  void toggleCategoryGroup(dynamic categoryOrSubcategories) {
    state = state.toggleCategoryGroup(categoryOrSubcategories);
  }

  /// Enables all subcategories.
  void enableAll([Iterable<String>? subcategories]) {
    state = state.enableAll(subcategories);
  }

  /// Disables all subcategories.
  void disableAll() {
    state = state.disableAll();
  }

  /// Legacy helper for backwards compatibility.
  void toggleCategory(String category) {
    toggleCategoryGroup(category);
  }

  /// Legacy helper to initialize categories when loaded.
  void initializeCategories(List<String> categories) {
    if (!_isInitialized && categories.isNotEmpty) {
      final current = Set<String>.from(state.enabledSubcategories);
      for (final cat in categories) {
        if (MapFilterState.categorySubcategories.containsKey(cat)) {
          current.addAll(MapFilterState.categorySubcategories[cat]!);
        } else {
          current.add(cat);
        }
      }
      state = MapFilterState(enabledSubcategories: current);
      _isInitialized = true;
    }
  }
}

/// Central filter state provider
final mapFilterProvider = StateNotifierProvider<MapFilterNotifier, MapFilterState>((ref) {
  return MapFilterNotifier();
});

/// Telemetry statistics for an individual subcategory
class SubcategoryCompletionStats {
  final String subCategory;
  final String displayName;
  final int totalCount;
  final int collectedCount;
  final bool isCollectable;

  const SubcategoryCompletionStats({
    required this.subCategory,
    required this.displayName,
    required this.totalCount,
    required this.collectedCount,
    required this.isCollectable,
  });

  int get remainingCount => totalCount - collectedCount;
  double get percentage => totalCount == 0 ? 0.0 : collectedCount / totalCount;
}

/// Statistics for a single category's completion status
class CategoryCompletionStats {
  final String category;
  final String displayName;
  final int totalCount;
  final int collectedCount;
  final List<SubcategoryCompletionStats> subcategoryStats;

  const CategoryCompletionStats({
    required this.category,
    required this.displayName,
    required this.totalCount,
    required this.collectedCount,
    this.subcategoryStats = const [],
  });

  int get remainingCount => totalCount - collectedCount;
  double get percentage => totalCount == 0 ? 0.0 : collectedCount / totalCount;
}

/// Overall completion telemetry for collectable map items
class MapCompletionSummary {
  final int totalCount;
  final int collectedCount;
  final List<CategoryCompletionStats> categoryStats;

  const MapCompletionSummary({
    required this.totalCount,
    required this.collectedCount,
    required this.categoryStats,
  });

  int get remainingCount => totalCount - collectedCount;
  double get percentage => totalCount == 0 ? 0.0 : collectedCount / totalCount;
}

/// Real-time summary provider computing completion percentages across all collectables and subcategories
final mapCompletionSummaryProvider = Provider<MapCompletionSummary>((ref) {
  final pois = ref.watch(mapPoiProvider).valueOrNull ?? [];
  final collectedIds = ref.watch(collectionTrackerProvider);

  final allCollectables = pois.where((p) => p.isCollectable).toList();
  final totalCollectable = allCollectables.length;
  final collectedTotal = allCollectables.where((p) => collectedIds.contains(p.id)).length;

  // Group POIs by category
  final Map<String, List<MapPointOfInterest>> poisByCategory = {};
  for (final poi in pois) {
    poisByCategory.putIfAbsent(poi.category, () => []).add(poi);
  }

  // Canonical category ordering
  final orderedCategories = <String>[
    'collectibles',
    'stunts',
    'services',
    'secrets_world',
    ...poisByCategory.keys.where(
      (c) => !['collectibles', 'stunts', 'services', 'secrets_world'].contains(c),
    ),
  ];

  final List<CategoryCompletionStats> categoryStatsList = [];

  for (final category in orderedCategories) {
    final catPois = poisByCategory[category] ?? [];
    if (catPois.isEmpty && pois.isNotEmpty) {
      continue;
    }

    final definedOrder = MapFilterState.categorySubcategories[category] ?? [];
    final subCatKeys = catPois.map((p) => p.subCategory).toSet().toList();
    subCatKeys.sort((a, b) {
      final idxA = definedOrder.indexOf(a);
      final idxB = definedOrder.indexOf(b);
      if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
      if (idxA != -1) return -1;
      if (idxB != -1) return 1;
      return a.compareTo(b);
    });

    final List<SubcategoryCompletionStats> subStatsList = [];
    for (final subCat in subCatKeys) {
      final subPois = catPois.where((p) => p.subCategory == subCat).toList();
      final subTotal = subPois.length;
      final subCollected = subPois.where((p) => collectedIds.contains(p.id)).length;
      final isSubCollectable = subPois.any((p) => p.isCollectable);

      subStatsList.add(
        SubcategoryCompletionStats(
          subCategory: subCat,
          displayName: getSubcategoryDisplayName(subCat),
          totalCount: subTotal,
          collectedCount: subCollected,
          isCollectable: isSubCollectable,
        ),
      );
    }

    // Category-level aggregate counts
    final catCollectables = catPois.where((p) => p.isCollectable).toList();
    final int catTotal;
    final int catCollected;

    if (catCollectables.isNotEmpty) {
      catTotal = catCollectables.length;
      catCollected = catCollectables.where((p) => collectedIds.contains(p.id)).length;
    } else {
      catTotal = catPois.length;
      catCollected = catPois.where((p) => collectedIds.contains(p.id)).length;
    }

    categoryStatsList.add(
      CategoryCompletionStats(
        category: category,
        displayName: getCategoryDisplayName(category),
        totalCount: catTotal,
        collectedCount: catCollected,
        subcategoryStats: subStatsList,
      ),
    );
  }

  return MapCompletionSummary(
    totalCount: totalCollectable,
    collectedCount: collectedTotal,
    categoryStats: categoryStatsList,
  );
});
