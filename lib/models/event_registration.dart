/// Event registration model
/// Represents a user's registration for an adoption event
class EventRegistration {
  final String id;
  final String eventId;
  final String userId;
  final String userName;
  final String userEmail;
  final String? userPhone;
  final DateTime registeredAt;
  final String status; // 'registered', 'cancelled', 'attended'

  EventRegistration({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    this.userPhone,
    required this.registeredAt,
    this.status = 'registered',
  });

  /// Create from Firestore document
  factory EventRegistration.fromMap(String id, Map<String, dynamic> map) {
    return EventRegistration(
      id: id,
      eventId: map['eventId'] ?? '',
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userPhone: map['userPhone'],
      registeredAt: map['registeredAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['registeredAt'].millisecondsSinceEpoch)
          : DateTime.now(),
      status: map['status'] ?? 'registered',
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'registeredAt': registeredAt,
      'status': status,
    };
  }

  /// Create a copy with updated fields
  EventRegistration copyWith({
    String? id,
    String? eventId,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    DateTime? registeredAt,
    String? status,
  }) {
    return EventRegistration(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      registeredAt: registeredAt ?? this.registeredAt,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'EventRegistration(id: $id, eventId: $eventId, userName: $userName, status: $status)';
  }
}
