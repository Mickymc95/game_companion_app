import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../sdk/models/map_poi.dart';

// Provides the active map layer type (true for road, false for satellite)
final isRoadLayerProvider = StateProvider<bool>((ref) => true);

// FutureProvider to load the points of interest from the JSON asset
final mapPoiProvider = FutureProvider<List<MapPointOfInterest>>((ref) async {
  final jsonString = await rootBundle.loadString('assets/data/gtav_map_pois.json');
  final List<dynamic> jsonList = json.decode(jsonString);

  return jsonList.map((json) => MapPointOfInterest.fromJson(json)).toList();
});

// Provides all unique categories from the loaded POIs
final mapCategoriesProvider = Provider<List<String>>((ref) {
  final pois = ref.watch(mapPoiProvider).valueOrNull ?? [];
  return pois.map((poi) => poi.category).toSet().toList();
});

// Notifier to manage the set of actively selected/filtered categories
class MapFilterNotifier extends StateNotifier<Set<String>> {
  bool _isInitialized = false;

  MapFilterNotifier() : super({});

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
