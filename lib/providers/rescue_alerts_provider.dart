import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/rescue_report.dart';
import '../utils/rescue_alerts.dart';

/// "Rescues near you" for volunteers/rescuers.
///
/// While the app is open this watches the open rescue reports and works out,
/// on the device, which ones fall inside the rescuer's chosen area. The
/// settings live in SharedPreferences (per account).
///
/// Phone notifications are a separate opt-in ([RescueAlertPrefs.pushEnabled])
/// handled through a [RescuePushGateway]; only then is the area uploaded.
class RescueAlertsProvider extends ChangeNotifier {
  /// Opens the stream of pending rescue reports.
  final Stream<List<RescueReport>> Function() _pendingReports;

  /// Null where phone notifications are not available (tests, admin web).
  final RescuePushGateway? _push;

  RescueAlertsProvider(this._pendingReports, {RescuePushGateway? push}) : _push = push;

  /// This device can receive rescue phone notifications.
  bool get pushSupported => _push?.supported ?? false;

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
    // A different account (or nobody) is now signed in on this phone: stop
    // delivering the previous rescuer's notifications here.
    if (uid != _uid && _uid != null && _prefs.pushEnabled && pushSupported) {
      unawaited(_push!.forgetDevice().catchError((_) {}));
    }
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
    // Keep the server copy fresh: the device token can change between runs.
    if (_prefs.wantsPush && pushSupported) {
      unawaited(_push!.subscribe(uid, _prefs).then((_) {}).catchError((_) {}));
    }
  }

  /// Saves the rescuer's settings on this device and applies them.
  ///
  /// Returns false when phone notifications were asked for but could not be
  /// switched on (permission refused, offline); everything else is still
  /// saved, with phone notifications off.
  Future<bool> savePrefs(RescueAlertPrefs prefs) async {
    final uid = _uid;
    if (uid == null) return true;
    final hadPush = _prefs.wantsPush;
    var pushOk = true;
    if (pushSupported) {
      if (prefs.wantsPush) {
        try {
          pushOk = await _push!.subscribe(uid, prefs);
        } catch (_) {
          pushOk = false;
        }
        if (!pushOk) prefs = prefs.copyWith(pushEnabled: false);
      }
      if (!prefs.wantsPush && (hadPush || !pushOk)) {
        // Switched off (or failed): remove the area from the server.
        try {
          await _push!.unsubscribe(uid);
        } catch (_) {
          // Retried the next time settings are saved.
        }
      }
    } else if (prefs.pushEnabled) {
      prefs = prefs.copyWith(pushEnabled: false);
    }
    if (uid != _uid) return pushOk;
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
    return pushOk;
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
