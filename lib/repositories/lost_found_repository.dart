import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lost_found.dart';

class LostFoundRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all lost & found reports as a stream with optional type filter
  Stream<List<LostFound>> getLostFoundStream({String? typeFilter}) {
    Query query = _firestore
        .collection('lostfound')
        .orderBy('createdAt', descending: true);

    if (typeFilter != null && typeFilter != 'All') {
      query = query.where('type', isEqualTo: typeFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return LostFound.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Add a new lost/found report
  Future<void> addLostFound(LostFound report) async {
    await _firestore.collection('lostfound').add({
      ...report.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing report
  Future<void> updateLostFound(LostFound report) async {
    await _firestore.collection('lostfound').doc(report.id).update(report.toMap());
  }

  // Delete a report
  Future<void> deleteLostFound(String id) async {
    await _firestore.collection('lostfound').doc(id).delete();
  }

  // Get a single report by ID
  Future<LostFound?> getLostFoundById(String id) async {
    final doc = await _firestore.collection('lostfound').doc(id).get();
    if (!doc.exists) return null;
    return LostFound.fromMap(doc.id, doc.data());
  }

  // Get reports by user ID
  Stream<List<LostFound>> getUserReportsStream(String userId) {
    return _firestore
        .collection('lostfound')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return LostFound.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  // Search reports by location or description
  Future<List<LostFound>> searchReports(String query) async {
    final snapshot = await _firestore.collection('lostfound').get();
    final searchLower = query.toLowerCase();

    return snapshot.docs
        .map((doc) => LostFound.fromMap(doc.id, doc.data()))
        .where((report) =>
            report.description.toLowerCase().contains(searchLower) ||
            report.location.toLowerCase().contains(searchLower) ||
            report.animalType.toLowerCase().contains(searchLower))
        .toList();
  }
}
