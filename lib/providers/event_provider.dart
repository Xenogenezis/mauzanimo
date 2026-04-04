import 'package:flutter/material.dart';
import '../repositories/event_repository.dart';
import '../models/event_registration.dart';
import '../utils/result.dart';

/// Provider for event registration state management
class EventProvider extends ChangeNotifier {
  final EventRepository _eventRepository;

  bool _isLoading = false;
  String? _error;
  String? _successMessage;

  EventProvider(this._eventRepository);

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get successMessage => _successMessage;

  /// Clear messages
  void clearMessages() {
    _error = null;
    _successMessage = null;
    notifyListeners();
  }

  /// Register for an event
  Future<bool> registerForEvent({
    required String eventId,
    required String userId,
    required String userName,
    required String userEmail,
    String? userPhone,
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    final result = await _eventRepository.registerForEvent(
      eventId: eventId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPhone: userPhone,
    );

    _isLoading = false;

    result.when(
      success: (_) {
        _successMessage = 'Successfully registered for event!';
      },
      failure: (message) {
        _error = message;
      },
    );

    notifyListeners();
    return result.isSuccess;
  }

  /// Cancel event registration
  Future<bool> cancelRegistration({
    required String eventId,
    required String userId,
  }) async {
    _isLoading = true;
    _error = null;
    _successMessage = null;
    notifyListeners();

    final result = await _eventRepository.cancelRegistration(
      eventId: eventId,
      userId: userId,
    );

    _isLoading = false;

    result.when(
      success: (_) {
        _successMessage = 'Registration cancelled.';
      },
      failure: (message) {
        _error = message;
      },
    );

    notifyListeners();
    return result.isSuccess;
  }

  /// Check if user is registered for an event
  Stream<bool> isUserRegisteredForEvent({
    required String eventId,
    required String userId,
  }) {
    final result = _eventRepository.isUserRegisteredForEvent(
      eventId: eventId,
      userId: userId,
    );

    return result.when(
      success: (stream) => stream,
      failure: (message) {
        _error = message;
        notifyListeners();
        return Stream.value(false);
      },
    );
  }

  /// Get user's event registrations
  Stream<List<EventRegistration>> getUserRegistrations(String userId) {
    final result = _eventRepository.getUserRegistrations(userId);

    return result.when(
      success: (stream) => stream,
      failure: (message) {
        _error = message;
        notifyListeners();
        return Stream.value([]);
      },
    );
  }

  /// Get registrations for a specific event (admin use)
  Stream<List<EventRegistration>> getEventRegistrations(String eventId) {
    final result = _eventRepository.getEventRegistrations(eventId);

    return result.when(
      success: (stream) => stream,
      failure: (message) {
        _error = message;
        notifyListeners();
        return Stream.value([]);
      },
    );
  }
}
