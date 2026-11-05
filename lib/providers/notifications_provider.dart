import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/app_notification.dart';
import '../repositories/notification_repository.dart';

/// Live list of the signed-in user's in-app notifications.
///
/// Follows the auth state through [setUid] (wired with a
/// ChangeNotifierProxyProvider in main.dart).
class NotificationsProvider extends ChangeNotifier {
  final NotificationRepository _repository;
  StreamSubscription<List<AppNotification>>? _sub;
  String? _uid;
  List<AppNotification> _items = const [];
  bool _loading = false;
  bool _hasError = false;
  bool _disposed = false;

  NotificationsProvider(this._repository, [String? uid]) {
    if (uid != null) _listen(uid);
  }

  String? get uid => _uid;
  List<AppNotification> get items => _items;
  int get unreadCount => _items.where((n) => !n.read).length;
  bool get isLoading => _loading;
  bool get hasError => _hasError;

  /// Switch to another user (or none). Safe to call during build: the
  /// listeners are notified after the current frame's microtasks.
  void setUid(String? uid) {
    if (uid == _uid) return;
    _sub?.cancel();
    _sub = null;
    _items = const [];
    _hasError = false;
    _loading = false;
    _uid = null;
    if (uid != null) _listen(uid);
    scheduleMicrotask(_notify);
  }

  void _listen(String uid) {
    _uid = uid;
    _loading = true;
    _sub = _repository.watchFor(uid).listen(
      (list) {
        _items = list;
        _loading = false;
        _hasError = false;
        _notify();
      },
      onError: (Object e) {
        _loading = false;
        _hasError = true;
        _notify();
      },
    );
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Optimistic local update, then the write. Errors are swallowed: the
  /// stream will bring back the real state.
  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    _items = [for (final i in _items) i.id == n.id ? i.copyWith(read: true) : i];
    _notify();
    try {
      await _repository.markRead(n.id);
    } catch (e) {
      debugPrint('markRead failed: $e');
    }
  }

  Future<void> markAllRead() async {
    final ids = [for (final n in _items) if (!n.read) n.id];
    if (ids.isEmpty) return;
    _items = [for (final n in _items) n.read ? n : n.copyWith(read: true)];
    _notify();
    try {
      await _repository.markAllRead(ids);
    } catch (e) {
      debugPrint('markAllRead failed: $e');
    }
  }

  Future<void> delete(AppNotification n) async {
    _items = [for (final i in _items) if (i.id != n.id) i];
    _notify();
    try {
      await _repository.delete(n.id);
    } catch (e) {
      debugPrint('delete notification failed: $e');
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _sub?.cancel();
    super.dispose();
  }
}
