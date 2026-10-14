import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

final collectionTrackerProvider = StateNotifierProvider<CollectionTrackerNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CollectionTrackerNotifier(prefs);
});

class CollectionTrackerNotifier extends StateNotifier<Set<String>> {
  final SharedPreferences _prefs;
  static const _keyPrefix = 'collected_';

  CollectionTrackerNotifier(this._prefs) : super({}) {
    _loadInitialState();
  }

  void _loadInitialState() {
    final collected = <String>{};
    for (final key in _prefs.getKeys()) {
      if (key.startsWith(_keyPrefix) && _prefs.getBool(key) == true) {
        collected.add(key.substring(_keyPrefix.length));
      }
    }
    state = collected;
  }

  void toggleCollection(String id) {
    final isCollected = state.contains(id);
    if (isCollected) {
      _prefs.remove('$_keyPrefix$id');
      state = {...state}..remove(id);
    } else {
      _prefs.setBool('$_keyPrefix$id', true);
      state = {...state, id};
    }
  }

  bool isCollected(String id) {
    return state.contains(id);
  }
}
