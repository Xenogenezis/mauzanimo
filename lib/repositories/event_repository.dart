import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_registration.dart';
import '../utils/result.dart';

/// Repository for managing events and event registrations
class EventRepository {
  final FirebaseFirestore _firestore;

  EventRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Register a user for an event
  Future<Result<void>> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
    String? userPhone,
  }) async {
    try {
      // Check if user is already registered
      final existingQuery = await _firestore
          .collection('event_registrations')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'registered')
          .get();

      if (existingQuery.docs.isNotEmpty) {
        return Result.failure('You are already registered for this event.');
      }

      // Create registration
      await _firestore.collection('event_registrations').add({
        'eventId': eventId,
        'userId': userId,
        'userName': userName,
        'userEmail': userEmail,
        'userPhone': userPhone,
        'registeredAt': FieldValue.serverTimestamp(),
        'status': 'registered',
      });

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to register for event. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Cancel a user's registration for an event
  Future<Result<void>> cancelRegistration({
    required String eventId,
    required String userId,
  }) async {
    try {
      final query = await _firestore
          .collection('event_registrations')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'registered')
          .get();

      if (query.docs.isEmpty) {
        return Result.failure('Registration not found.');
      }

      await query.docs.first.reference.update({
        'status': 'cancelled',
      });

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to cancel registration. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if a user is registered for an event
  Result<Stream<bool>> isUserRegisteredForEvent({
    required String eventId,
    required String userId,
  }) {
    try {
      final stream = _firestore
          .collection('event_registrations')
          .where('eventId', isEqualTo: eventId)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'registered')
          .snapshots()
          .map((snapshot) => snapshot.docs.isNotEmpty);

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to check registration status.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get all registrations for a specific event
  Result<Stream<List<EventRegistration>>> getEventRegistrations(String eventId) {
    try {
      final stream = _firestore
          .collection('event_registrations')
          .where('eventId', isEqualTo: eventId)
          .orderBy('registeredAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return EventRegistration.fromMap(
            doc.id,
            doc.data(),
          );
        }).toList();
      });

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load registrations.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get all registrations for a specific user
  Result<Stream<List<EventRegistration>>> getUserRegistrations(String userId) {
    try {
      final stream = _firestore
          .collection('event_registrations')
          .where('userId', isEqualTo: userId)
          .orderBy('registeredAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return EventRegistration.fromMap(
            doc.id,
            doc.data(),
          );
        }).toList();
      });

      return Result.success(stream);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load your registrations.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update registration status (for admin use)
  Future<Result<void>> updateRegistrationStatus({
    required String registrationId,
    required String status,
  }) async {
    try {
      await _firestore
          .collection('event_registrations')
          .doc(registrationId)
          .update({'status': status});

      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to update registration.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
