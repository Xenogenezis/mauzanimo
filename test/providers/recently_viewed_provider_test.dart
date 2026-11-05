import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/providers/recently_viewed_provider.dart';

void main() {
  group('RecentlyViewedProvider.addToFront', () {
    test('adds a new id to the front', () {
      expect(RecentlyViewedProvider.addToFront(['a', 'b'], 'c'), ['c', 'a', 'b']);
    });

    test('adds to an empty list', () {
      expect(RecentlyViewedProvider.addToFront([], 'a'), ['a']);
    });

    test('moves an existing id to the front without duplicating it', () {
      expect(RecentlyViewedProvider.addToFront(['a', 'b', 'c'], 'c'), ['c', 'a', 'b']);
      expect(RecentlyViewedProvider.addToFront(['a', 'b', 'c'], 'a'), ['a', 'b', 'c']);
    });

    test('caps the list at 10 by dropping the oldest', () {
      final ids = List.generate(10, (i) => 'p$i');
      final result = RecentlyViewedProvider.addToFront(ids, 'new');
      expect(result.length, 10);
      expect(result.first, 'new');
      expect(result.contains('p9'), isFalse);
      expect(result.last, 'p8');
    });

    test('respects a custom max', () {
      expect(RecentlyViewedProvider.addToFront(['a', 'b', 'c'], 'd', max: 2), ['d', 'a']);
    });

    test('ignores empty ids and does not mutate the input', () {
      final input = ['a', 'b'];
      expect(RecentlyViewedProvider.addToFront(input, ''), ['a', 'b']);
      RecentlyViewedProvider.addToFront(input, 'c');
      expect(input, ['a', 'b']);
    });
  });

  group('RecentlyViewedProvider persistence', () {
    test('loads stored ids on construction', () async {
      SharedPreferences.setMockInitialValues({
        RecentlyViewedProvider.prefsKey: ['x', 'y'],
      });
      final provider = RecentlyViewedProvider();
      await provider.record('x'); // waits for the initial load
      expect(provider.ids, ['x', 'y']);
    });

    test('record persists most recent first and clear empties storage', () async {
      SharedPreferences.setMockInitialValues({});
      final provider = RecentlyViewedProvider();
      var notifications = 0;
      provider.addListener(() => notifications++);

      await provider.record('a');
      await provider.record('b');
      await provider.record('a');
      expect(provider.ids, ['a', 'b']);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList(RecentlyViewedProvider.prefsKey), ['a', 'b']);

      await provider.clear();
      expect(provider.ids, isEmpty);
      expect(prefs.getStringList(RecentlyViewedProvider.prefsKey), isEmpty);
      expect(notifications, greaterThanOrEqualTo(4));
    });

    test('a record made before loading finishes keeps the stored history', () async {
      SharedPreferences.setMockInitialValues({
        RecentlyViewedProvider.prefsKey: ['old'],
      });
      final provider = RecentlyViewedProvider();
      await provider.record('new');
      expect(provider.ids, ['new', 'old']);
    });
  });
}
