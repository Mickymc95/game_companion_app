import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:game_companion_sdk/sdk/storage/collection_tracker.dart';

void main() {
  group('CollectionTrackerService', () {
    late SharedPreferences prefs;
    late CollectionTrackerNotifier tracker;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      tracker = CollectionTrackerNotifier(prefs);
    });

    test('Initial state is empty', () {
      expect(tracker.state, isEmpty);
      expect(tracker.isCollected('poi_1'), isFalse);
    });

    test('Toggle collection updates state and prefs', () {
      tracker.toggleCollection('poi_1');

      expect(tracker.state, contains('poi_1'));
      expect(tracker.isCollected('poi_1'), isTrue);
      expect(prefs.getBool('collected_poi_1'), isTrue);

      tracker.toggleCollection('poi_1');

      expect(tracker.state, isNot(contains('poi_1')));
      expect(tracker.isCollected('poi_1'), isFalse);
      expect(prefs.getBool('collected_poi_1'), isNull);
    });

    test('Loads initial state from prefs correctly', () async {
      SharedPreferences.setMockInitialValues({
        'collected_poi_1': true,
        'collected_poi_2': true,
        'other_key': 'value',
      });
      final newPrefs = await SharedPreferences.getInstance();
      final newTracker = CollectionTrackerNotifier(newPrefs);

      expect(newTracker.state, containsAll(['poi_1', 'poi_2']));
    });
  });
}
