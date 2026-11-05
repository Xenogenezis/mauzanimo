import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps the IDs of the pets the user opened most recently, on this device.
///
/// Only IDs are stored: pet documents embed base64 photos that can be close
/// to 1 MB, which must never end up in SharedPreferences.
class RecentlyViewedProvider extends ChangeNotifier {
  static const String prefsKey = 'recently_viewed_pet_ids';
  static const int maxItems = 10;

  List<String> _ids = const [];
  List<String> get ids => _ids;

  late final Future<void> _loaded;

  RecentlyViewedProvider() {
    _loaded = _load();
  }

  /// Returns [current] with [petId] moved (or added) to the front,
  /// without duplicates and capped at [max] entries.
  static List<String> addToFront(List<String> current, String petId, {int max = maxItems}) {
    if (petId.isEmpty) return List.unmodifiable(current);
    final updated = <String>[petId, ...current.where((id) => id != petId)];
    return List.unmodifiable(updated.take(max));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(prefsKey) ?? const <String>[];
      // Normalise whatever was stored (dedupe + cap) by replaying it oldest first.
      var ids = const <String>[];
      for (final id in stored.reversed) {
        ids = addToFront(ids, id);
      }
      _ids = ids;
      notifyListeners();
    } catch (_) {
      // Recently viewed is a convenience; never break the app over it.
    }
  }

  Future<void> record(String petId) async {
    await _loaded;
    final updated = addToFront(_ids, petId);
    if (_sameOrder(updated, _ids)) return;
    _ids = updated;
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    await _loaded;
    if (_ids.isEmpty) return;
    _ids = const [];
    notifyListeners();
    await _save();
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(prefsKey, _ids);
    } catch (_) {}
  }

  static bool _sameOrder(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
