/// User roles for role-based access control
enum UserRole {
  adopter,    // Default - can adopt pets
  rehomer,    // Can list pets for rehoming
  volunteer,  // Can help with events, rescue
  partner,    // Vets, shelters, NGOs - Admin created only
  admin,      // Full system access - Admin created only
  superAdmin, // Can manage other admins - Admin created only
}

extension UserRoleExtension on UserRole {
  /// Display name for the role
  String get displayName {
    return switch (this) {
      UserRole.adopter => 'Adopter',
      UserRole.rehomer => 'Rehomer',
      UserRole.volunteer => 'Volunteer',
      UserRole.partner => 'Partner',
      UserRole.admin => 'Admin',
      UserRole.superAdmin => 'Super Admin',
    };
  }

  /// Description of what the role can do
  String get description {
    return switch (this) {
      UserRole.adopter => 'Looking to adopt a pet',
      UserRole.rehomer => 'Need to rehome a pet',
      UserRole.volunteer => 'Want to help at events',
      UserRole.partner => 'Vet clinic, shelter, or NGO',
      UserRole.admin => 'System administrator',
      UserRole.superAdmin => 'Super administrator',
    };
  }

  /// Permission level (higher = more access)
  int get permissionLevel {
    return switch (this) {
      UserRole.adopter => 1,
      UserRole.rehomer => 2,
      UserRole.volunteer => 3,
      UserRole.partner => 4,
      UserRole.admin => 5,
      UserRole.superAdmin => 10,
    };
  }

  /// Whether this role can be selected during registration
  bool get isSelfAssignable {
    return this == UserRole.adopter ||
           this == UserRole.rehomer ||
           this == UserRole.volunteer;
  }

  /// Check if this role has access to required role level
  bool canAccess(UserRole requiredRole) =>
      permissionLevel >= requiredRole.permissionLevel;

  /// Parse role from string
  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => UserRole.adopter,
    );
  }
}

/// Available roles for registration
final List<UserRole> selfAssignableRoles = [
  UserRole.adopter,
  UserRole.rehomer,
  UserRole.volunteer,
];
