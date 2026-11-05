import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/utils/offline_write.dart';

void main() {
  test('returns synced when the write completes in time', () async {
    final r = await writeOfflineFirst(Future<void>.value(), wait: const Duration(milliseconds: 50));
    expect(r, WriteOutcome.synced);
  });

  test('returns queued when the server never answers (offline)', () async {
    final never = Completer<void>().future;
    final r = await writeOfflineFirst(never, wait: const Duration(milliseconds: 20));
    expect(r, WriteOutcome.queued);
  });

  test('a late failure after queuing is swallowed, not unhandled', () async {
    final c = Completer<void>();
    final r = await writeOfflineFirst(c.future, wait: const Duration(milliseconds: 10));
    expect(r, WriteOutcome.queued);
    c.completeError(StateError('rejected by rules'));
    await Future<void>.delayed(const Duration(milliseconds: 10));
  });

  test('an immediate failure is rethrown so the UI can show it', () async {
    expect(
      writeOfflineFirst(Future<void>.error(StateError('denied'))),
      throwsStateError,
    );
  });
}
