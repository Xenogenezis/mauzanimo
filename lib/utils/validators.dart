class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? required(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return fieldName != null ? '$fieldName is required' : 'This field is required';
    }
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Phone is optional
    }
    // Basic phone validation - allows international formats
    final phoneRegex = RegExp(r'^[\d\s\+\-\(\)\.]+$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Please enter a valid phone number';
    }
    // Check minimum length (at least 7 digits)
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 7) {
      return 'Phone number is too short';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 6}) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != originalPassword) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? minLength(String? value, int minLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null; // Optional field
    }
    if (value.length < minLength) {
      final name = fieldName ?? 'Field';
      return '$name must be at least $minLength characters';
    }
    return null;
  }

  static String? maxLength(String? value, int maxLength, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (value.length > maxLength) {
      final name = fieldName ?? 'Field';
      return '$name must be no more than $maxLength characters';
    }
    return null;
  }

  /// Registration password rule: returns an `accountStrings` key describing
  /// the first unmet requirement, or null when the password is acceptable.
  static String? strongPassword(String? value, {String? email}) {
    final check = PasswordStrength.check(value ?? '', email: email);
    if ((value ?? '').isEmpty) return 'acct_pw_required';
    if (!check.longEnough) return 'acct_pw_too_short';
    if (!check.hasLetter || !check.hasDigit) return 'acct_pw_letters_digits';
    if (!check.differsFromEmail) return 'acct_pw_same_as_email';
    return null;
  }
}

/// Result of checking a password against the registration rules.
class PasswordStrength {
  static const int minLength = 8;

  final bool longEnough;
  final bool hasLetter;
  final bool hasDigit;
  final bool differsFromEmail;

  /// Bonus signals for the meter only (not required).
  final bool hasSymbolOrMixedCase;
  final bool veryLong;

  const PasswordStrength._({
    required this.longEnough,
    required this.hasLetter,
    required this.hasDigit,
    required this.differsFromEmail,
    required this.hasSymbolOrMixedCase,
    required this.veryLong,
  });

  factory PasswordStrength.check(String password, {String? email}) {
    final e = (email ?? '').trim().toLowerCase();
    final p = password.trim().toLowerCase();
    final localPart = e.contains('@') ? e.substring(0, e.indexOf('@')) : e;
    return PasswordStrength._(
      longEnough: password.length >= minLength,
      hasLetter: RegExp(r'[A-Za-z\u00C0-\u024F]').hasMatch(password),
      hasDigit: RegExp(r'\d').hasMatch(password),
      differsFromEmail:
          p.isEmpty || e.isEmpty || (p != e && (localPart.isEmpty || p != localPart)),
      hasSymbolOrMixedCase: RegExp(r'[^A-Za-z0-9]').hasMatch(password) ||
          (RegExp(r'[a-z]').hasMatch(password) && RegExp(r'[A-Z]').hasMatch(password)),
      veryLong: password.length >= 12,
    );
  }

  /// All required rules pass, so registration may proceed.
  bool get isAcceptable => longEnough && hasLetter && hasDigit && differsFromEmail;

  /// 0 (empty/very weak) .. 4 (strong), for the meter.
  int get score {
    if (!isAcceptable) {
      final met = [longEnough, hasLetter && hasDigit, differsFromEmail].where((b) => b).length;
      return met >= 2 ? 1 : 0;
    }
    return 2 + (hasSymbolOrMixedCase ? 1 : 0) + (veryLong ? 1 : 0);
  }
}
