import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rescue_report.dart';
import '../utils/result.dart';

class RescueRepository {
  final FirebaseFirestore _firestore;
  RescueRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<Result<void>> createReport(RescueReport report) async {
    try {
      await _firestore.collection('rescue_reports').add(report.toMap());
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Firestore error', error: e);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Future<Result<void>> assignVolunteer(String id, String volunteerId, String volunteerName) async {
    try {
      await _firestore.collection('rescue_reports').doc(id).update({
        'status': 'assigned',
        'assignedVolunteerId': volunteerId,
        'assignedVolunteerName': volunteerName,
      });
      return Result.success(null);
    } on FirebaseException catch (e) {
      return Result.failure(e.message ?? 'Firestore error', error: e);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }

  Result<Stream<List<RescueReport>>> getReportsStream() {
    try {
      final stream = _firestore
          .collection('rescue_reports')
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((s) => s.docs.map((d) => RescueReport.fromMap(d.id, d.data())).toList());
      return Result.success(stream);
    } catch (e) {
      return Result.failure(e.toString(), error: e);
    }
  }
}
