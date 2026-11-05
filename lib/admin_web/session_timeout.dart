// Auto sign-out of the web admin after a period of inactivity.
//
// [IdleTimeout] is the pure timer logic (testable with fake timers);
// [IdleSignOut] wires it to pointer/keyboard activity, shows a warning
// dialog for the last minute and signs the admin out when time runs out.
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef TimerFactory = Timer Function(Duration duration, void Function() callback);

enum IdleState { active, warning, expired }

/// Fires [onWarning] after `timeout - warning` without [activity], then
/// [onTimeout] once the full [timeout] has passed. While the warning is up,
/// ordinary activity is ignored: only [stayActive] (the dialog's button)
/// extends the session, so a stray mouse move can't silently dismiss it.
class IdleTimeout {
  final Duration timeout;
  final Duration warning;
  final VoidCallback onWarning;
  final VoidCallback onTimeout;
  final TimerFactory _timer;

  Timer? _pending;
  IdleState _state = IdleState.active;
  bool _disposed = false;

  IdleTimeout({
    this.timeout = const Duration(minutes: 30),
    this.warning = const Duration(seconds: 60),
    required this.onWarning,
    required this.onTimeout,
    TimerFactory? timerFactory,
  })  : assert(warning < timeout),
        _timer = timerFactory ?? Timer.new;

  IdleState get state => _state;

  /// Starts (or restarts) the countdown from now.
  void start() {
    if (_disposed) return;
    _pending?.cancel();
    _state = IdleState.active;
    _pending = _timer(timeout - warning, _warn);
  }

  /// Pointer or keyboard activity. Resets the countdown unless the warning
  /// is showing or the session already expired.
  void activity() {
    if (_state == IdleState.active) start();
  }

  /// The user confirmed they are still there.
  void stayActive() {
    if (_state != IdleState.expired) start();
  }

  void _warn() {
    if (_disposed) return;
    _state = IdleState.warning;
    _pending = _timer(warning, _expire);
    onWarning();
  }

  void _expire() {
    if (_disposed) return;
    _state = IdleState.expired;
    _pending = null;
    onTimeout();
  }

  void dispose() {
    _disposed = true;
    _pending?.cancel();
    _pending = null;
  }
}

/// Signs the admin out after [timeout] of no pointer or keyboard input,
/// with a [warning]-long countdown dialog first.
class IdleSignOut extends StatefulWidget {
  final Widget child;
  final Duration timeout;
  final Duration warning;

  /// Defaults to `FirebaseAuth.instance.signOut`.
  final Future<void> Function()? signOut;

  const IdleSignOut({
    super.key,
    required this.child,
    this.timeout = const Duration(minutes: 30),
    this.warning = const Duration(seconds: 60),
    this.signOut,
  });

  @override
  State<IdleSignOut> createState() => _IdleSignOutState();
}

class _IdleSignOutState extends State<IdleSignOut> {
  late final IdleTimeout _idle = IdleTimeout(
    timeout: widget.timeout,
    warning: widget.warning,
    onWarning: _showWarning,
    onTimeout: _signOut,
  );
  NavigatorState? _dialogNavigator;

  @override
  void initState() {
    super.initState();
    _idle.start();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _idle.dispose();
    super.dispose();
  }

  bool _onKey(KeyEvent _) {
    _idle.activity();
    return false; // never consume the key
  }

  Future<void> _showWarning() async {
    if (!mounted) return;
    final nav = Navigator.of(context, rootNavigator: true);
    _dialogNavigator = nav;
    final stay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _IdleWarningDialog(seconds: widget.warning.inSeconds),
    );
    _dialogNavigator = null;
    if (!mounted) return;
    if (stay == true) {
      _idle.stayActive();
    } else if (stay == false) {
      _signOut();
    }
    // null: closed by _signOut after the timeout.
  }

  void _signOut() {
    final nav = _dialogNavigator;
    _dialogNavigator = null;
    if (nav != null && nav.mounted && nav.canPop()) nav.pop();
    _idle.dispose();
    (widget.signOut ?? FirebaseAuth.instance.signOut)().catchError((Object e) {
      debugPrint('Idle sign-out failed: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _idle.activity(),
      onPointerHover: (_) => _idle.activity(),
      onPointerSignal: (_) => _idle.activity(),
      child: widget.child,
    );
  }
}

class _IdleWarningDialog extends StatefulWidget {
  final int seconds;
  const _IdleWarningDialog({required this.seconds});

  @override
  State<_IdleWarningDialog> createState() => _IdleWarningDialogState();
}

class _IdleWarningDialogState extends State<_IdleWarningDialog> {
  late int _left = widget.seconds;
  late final Timer _tick = Timer.periodic(const Duration(seconds: 1), (_) {
    if (_left > 0) setState(() => _left--);
  });

  @override
  void initState() {
    super.initState();
    _tick; // start counting
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.timer_outlined),
      title: const Text('Still there?'),
      content: Text('For security you will be signed out in $_left seconds because of inactivity.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Sign out now')),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Stay signed in'),
        ),
      ],
    );
  }
}
