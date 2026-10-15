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

/// Notifier to manage the set of actively selected/filtered categories
class MapFilterNotifier extends StateNotifier<Set<String>> {
  bool _isInitialized = false;

  MapFilterNotifier() : super({'collectibles', 'stunts', 'services'});

  void toggleCategory(String category) {
    if (state.contains(category)) {
      state = {...state}..remove(category);
    } else {
      state = {...state, category};
    }
  }

  // Helper to initialize all categories when loaded
  void initializeCategories(List<String> categories) {
    if (!_isInitialized && categories.isNotEmpty) {
      state = categories.toSet();
      _isInitialized = true;
    }
  }
}

final mapFilterProvider = StateNotifierProvider<MapFilterNotifier, Set<String>>((ref) {
  return MapFilterNotifier();
});

/// Statistics for a single category's completion status
class CategoryCompletionStats {
  final String category;
  final int totalCount;
  final int collectedCount;

  const CategoryCompletionStats({
    required this.category,
    required this.totalCount,
    required this.collectedCount,
  });

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

  double get percentage => totalCount == 0 ? 0.0 : collectedCount / totalCount;
}

/// Real-time summary provider computing completion percentages across all collectables
final mapCompletionSummaryProvider = Provider<MapCompletionSummary>((ref) {
  final pois = ref.watch(mapPoiProvider).valueOrNull ?? [];
  final collectedIds = ref.watch(collectionTrackerProvider);

  int total = 0;
  int collected = 0;
  final Map<String, List<MapPointOfInterest>> grouped = {};

  for (final poi in pois) {
    if (poi.isCollectable) {
      total++;
      if (collectedIds.contains(poi.id)) {
        collected++;
      }
      grouped.putIfAbsent(poi.category, () => []).add(poi);
    }
  }

  final categoryStats = grouped.entries.map((entry) {
    final catTotal = entry.value.length;
    final catCollected = entry.value.where((p) => collectedIds.contains(p.id)).length;
    return CategoryCompletionStats(
      category: entry.key,
      totalCount: catTotal,
      collectedCount: catCollected,
    );
  }).toList();

  return MapCompletionSummary(
    totalCount: total,
    collectedCount: collected,
    categoryStats: categoryStats,
  );
});
