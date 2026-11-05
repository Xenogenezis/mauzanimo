import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/models/adoption.dart';

void main() {
  test('StageRecord.toMap uses a concrete Timestamp (arrayUnion-safe)', () {
    final when = DateTime(2026, 11, 5, 10, 30);
    final map = StageRecord(stage: AdoptionStage.screening, timestamp: when).toMap();
    expect(map['timestamp'], isA<Timestamp>());
    expect((map['timestamp'] as Timestamp).toDate(), when);
    final back = StageRecord.fromMap(map);
    expect(back.stage, AdoptionStage.screening);
    expect(back.timestamp, when);
  });
}
