import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rescue_report.dart';
import '../utils/rescue_alerts.dart';

/// "Rescues near you" for volunteers/rescuers.
///
/// Phase 1 of rescue alerts: there is no push notification. While the app is
/// open this watches the open rescue reports and works out, on the device,
/// which ones fall inside the rescuer's chosen area. The area itself lives in
/// SharedPreferences (per account) and is never uploaded.
class RescueAlertsProvider extends ChangeNotifier {
  /// Opens the stream of pending rescue reports.
  final Stream<List<RescueReport>> Function() _pendingReports;

  RescueAlertsProvider(this._pendingReports);

  static const int _maxSeen = 300;

  String? _uid;
  bool _canRescue = false;
  RescueAlertPrefs _prefs = const RescueAlertPrefs();
  List<RescueReport> _pending = const [];
  List<NearbyRescue> _nearby = const [];
  Set<String> _seen = {};
  StreamSubscription<List<RescueReport>>? _sub;
  int _loadToken = 0;

  /// The signed-in account may take rescue requests (volunteer/rescuer,
  /// partner or admin). Mirrors `isVolunteerOrAbove()` in firestore.rules.
  bool get canRescue => _canRescue;

  RescueAlertPrefs get prefs => _prefs;

  /// Open reports inside the rescuer's area, most urgent then nearest first.
  List<NearbyRescue> get nearby => _nearby;

  /// Nearby reports the rescuer has not looked at yet.
  int get unseenCount => _nearby.where((n) => !_seen.contains(n.report.id)).length;

  String _prefsKey(String uid) => 'rescue_alerts_$uid';
  String _seenKey(String uid) => 'rescue_alerts_seen_$uid';

  /// Follows sign-in/out and role changes (called by the proxy provider).
  void setUser(String? uid, {required bool canRescue}) {
    if (uid == _uid && canRescue == _canRescue) return;
    _uid = uid;
    _canRescue = canRescue;
    _prefs = const RescueAlertPrefs();
    _seen = {};
    _pending = const [];
    _nearby = const [];
    _stopListening();
    if (uid != null && canRescue) {
      unawaited(_load(uid));
    }
    // Called while the widget tree is building.
    scheduleMicrotask(notifyListeners);
  }

  Future<void> _load(String uid) async {
    final token = ++_loadToken;
    try {
      final sp = await SharedPreferences.getInstance();
      if (token != _loadToken || uid != _uid) return;
      _prefs = RescueAlertPrefs.decode(sp.getString(_prefsKey(uid)));
      _seen = (sp.getStringList(_seenKey(uid)) ?? const []).toSet();
    } catch (_) {
      // Keep the defaults (alerts off).
    }
    _syncListening();
    notifyListeners();
  }

  /// Saves the rescuer's settings on this device and applies them.
  Future<void> savePrefs(RescueAlertPrefs prefs) async {
    final uid = _uid;
    if (uid == null) return;
    _prefs = prefs;
    _recompute();
    _syncListening();
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(_prefsKey(uid), prefs.encode());
    } catch (_) {
      // Still applies for this session.
    }
  }

  /// The rescuer has looked at the nearby list: clear the "new" count.
  Future<void> markSeen() async {
    final uid = _uid;
    if (uid == null || unseenCount == 0) return;
    _seen = {..._seen, ..._nearby.map((n) => n.report.id)};
    if (_seen.length > _maxSeen) {
      _seen = _seen.toList().sublist(_seen.length - _maxSeen).toSet();
    }
    notifyListeners();
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setStringList(_seenKey(uid), _seen.toList());
    } catch (_) {
      // Only the badge is affected.
    }
  }

  void _syncListening() {
    final shouldListen = _uid != null && _canRescue && _prefs.isActive;
    if (!shouldListen) {
      _stopListening();
      if (_pending.isNotEmpty || _nearby.isNotEmpty) {
        _pending = const [];
        _nearby = const [];
      }
      return;
    }
    _sub ??= _pendingReports().listen(
      (reports) {
        _pending = reports;
        _recompute();
        notifyListeners();
      },
      onError: (_) {
        // Offline or signed out mid-stream: keep the last known list.
      },
    );
  }

  void _recompute() => _nearby = nearbyRescues(_pending, _prefs);

  void _stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}
