import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/admin_web/audit.dart';
import 'package:stray_pets_mu/admin_web/audit_log_page.dart';

void main() {
  group('buildAuditEntry', () {
    test('has exactly the fields firestore.rules allows', () {
      final e = buildAuditEntry(
          actorUid: 'u1', action: 'delete', collection: 'pets', docId: 'p1', summary: ' gone ', at: 1);
      expect(e.keys.toSet(), {'actorUid', 'action', 'collection', 'docId', 'summary', 'at'});
      expect(e['summary'], 'gone');
    });

    test('drops an empty summary', () {
      final e = buildAuditEntry(actorUid: 'u', action: 'a', collection: 'c', docId: 'd', summary: '  ', at: 1);
      expect(e.containsKey('summary'), isFalse);
    });

    test('clips strings to the rules limits', () {
      final e = buildAuditEntry(
        actorUid: 'u',
        action: 'a' * 100,
        collection: 'c' * 100,
        docId: 'd' * 200,
        summary: 's' * 900,
        at: 1,
      );
      expect((e['action'] as String).length, auditActionMax);
      expect((e['collection'] as String).length, auditCollectionMax);
      expect((e['docId'] as String).length, auditDocIdMax);
      expect((e['summary'] as String).length, auditSummaryMax);
    });
  });

  test('auditActions lists distinct actions sorted', () {
    expect(
      auditActions([
        {'action': 'delete'},
        {'action': 'create'},
        {'action': 'delete'},
        {'other': 1},
      ]),
      ['create', 'delete'],
    );
  });

  test('filterByAction', () {
    final rows = ['create:1', 'delete:2', 'create:3'];
    String? actionOf(String r) => r.split(':').first;
    expect(filterByAction(rows, null, actionOf), rows);
    expect(filterByAction(rows, 'create', actionOf), ['create:1', 'create:3']);
  });
}
