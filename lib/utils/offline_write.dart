import 'dart:async';

/// Outcome of a write made with [writeOfflineFirst].
enum WriteOutcome {
  /// The server confirmed the write.
  synced,

  /// No confirmation yet (usually offline). Firestore has the write in its
  /// local cache, shows it in queries immediately, and uploads it once the
  /// device is back online - even after an app restart.
  queued,
}

/// Firestore write futures only complete when the *server* acknowledges them,
/// so `await ref.set(...)` hangs forever without signal. This waits briefly
/// for a confirmation, then lets the UI move on while Firestore keeps the
/// write queued.
Future<WriteOutcome> writeOfflineFirst(
  Future<void> write, {
  Duration wait = const Duration(seconds: 4),
}) async {
  try {
    await write.timeout(wait);
    return WriteOutcome.synced;
  } on TimeoutException {
    // Keep a listener so a later rejection (e.g. rules) isn't an unhandled error.
    unawaited(write.catchError((_) {}));
    return WriteOutcome.queued;
  }
}
