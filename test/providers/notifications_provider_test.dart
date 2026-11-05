import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/models/app_notification.dart';
import 'package:stray_pets_mu/providers/notifications_provider.dart';
import 'package:stray_pets_mu/repositories/notification_repository.dart';

class FakeNotificationRepository extends NotificationRepository {
  final controllers = <String, StreamController<List<AppNotification>>>{};
  final markedRead = <String>[];
  final deleted = <String>[];

  @override
  Stream<List<AppNotification>> watchFor(String uid) =>
      (controllers[uid] ??= StreamController<List<AppNotification>>.broadcast()).stream;

  @override
  Future<void> markRead(String id) async => markedRead.add(id);

  @override
  Future<void> markAllRead(Iterable<String> ids) async => markedRead.addAll(ids);

  @override
  Future<void> delete(String id) async => deleted.add(id);
}

AppNotification n(String id, {bool read = false}) => AppNotification(
    id: id, toUid: 'alice', type: 'sighting', refCollection: 'lostfound', refId: 'l1', read: read);

void main() {
  late FakeNotificationRepository repo;
  late NotificationsProvider provider;

  setUp(() {
    repo = FakeNotificationRepository();
    provider = NotificationsProvider(repo);
  });
  tearDown(() => provider.dispose());

  test('signed out: nothing', () {
    expect(provider.items, isEmpty);
    expect(provider.unreadCount, 0);
  });

  test('listens to the uid and counts unread', () async {
    provider.setUid('alice');
    repo.controllers['alice']!.add([n('a'), n('b', read: true), n('c')]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.items.length, 3);
    expect(provider.unreadCount, 2);
  });

  test('markRead, markAllRead and delete update locally and call the repo', () async {
    provider.setUid('alice');
    repo.controllers['alice']!.add([n('a'), n('b'), n('c')]);
    await Future<void>.delayed(Duration.zero);

    await provider.markRead(provider.items.first);
    expect(provider.unreadCount, 2);
    expect(repo.markedRead, ['a']);

    await provider.markAllRead();
    expect(provider.unreadCount, 0);
    expect(repo.markedRead, ['a', 'b', 'c']);

    await provider.delete(provider.items.first);
    expect(provider.items.map((e) => e.id), ['b', 'c']);
    expect(repo.deleted, ['a']);
  });

  test('switching user clears the old list', () async {
    provider.setUid('alice');
    repo.controllers['alice']!.add([n('a')]);
    await Future<void>.delayed(Duration.zero);
    provider.setUid(null);
    expect(provider.items, isEmpty);
    // Late events from the old stream are ignored.
    repo.controllers['alice']!.add([n('x')]);
    await Future<void>.delayed(Duration.zero);
    expect(provider.items, isEmpty);
  });
}
