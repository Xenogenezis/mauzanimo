import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_role.dart';

class UserProfile {
  final String uid;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final DateTime? createdAt;

  UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.role = UserRole.adopter,
    this.createdAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      role: UserRoleExtension.fromString(map['role'] as String?),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'role': role.name,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    DateTime? createdAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper getters
  bool get isAdmin => role == UserRole.admin || role == UserRole.superAdmin;
  bool get isPartner => role == UserRole.partner;
  bool get isVolunteer => role == UserRole.volunteer;
  bool get canListPets => role.canAccess(UserRole.rehomer);
}
