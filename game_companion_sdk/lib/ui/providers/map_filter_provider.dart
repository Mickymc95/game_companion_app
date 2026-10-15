import 'package:flutter_riverpod/flutter_riverpod.dart';

final mapFilterProvider = StateNotifierProvider<MapFilterNotifier, Set<String>>((ref) {
  return MapFilterNotifier();
});

class MapFilterNotifier extends StateNotifier<Set<String>> {
  MapFilterNotifier() : super({'collectibles', 'stunts', 'services'});

  void toggleCategory(String category) {
    if (state.contains(category)) {
      state = {...state}..remove(category);
    } else {
      state = {...state, category};
    }
  }

  bool isCategoryEnabled(String category) {
    return state.contains(category);
  }
}
