import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/utils/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('should return null for valid email', () {
        expect(Validators.email('test@example.com'), isNull);
      });

      test('should return error for empty email', () {
        expect(Validators.email(''), isNotNull);
      });

      test('should return error for null email', () {
        expect(Validators.email(null), isNotNull);
      });

      test('should return error for invalid email', () {
        expect(Validators.email('not-an-email'), isNotNull);
      });
    });

    group('required', () {
      test('should return null for non-empty value', () {
        expect(Validators.required('hello'), isNull);
      });

      test('should return error for empty value', () {
        expect(Validators.required(''), isNotNull);
      });

      test('should return error for whitespace-only value', () {
        expect(Validators.required('   '), isNotNull);
      });

      test('should include field name in error', () {
        final error = Validators.required('', fieldName: 'Email');
        expect(error, contains('Email'));
      });
    });

    group('phone', () {
      test('should return null for empty phone (optional)', () {
        expect(Validators.phone(''), isNull);
        expect(Validators.phone(null), isNull);
      });

      test('should return null for valid phone', () {
        expect(Validators.phone('+230 5250 1234'), isNull);
        expect(Validators.phone('52501234'), isNull);
      });

      test('should return error for invalid phone', () {
        expect(Validators.phone('abc'), isNotNull);
      });

      test('should return error for too short phone', () {
        expect(Validators.phone('123'), isNotNull);
      });
    });

    group('password', () {
      test('should return null for valid password', () {
        expect(Validators.password('password123'), isNull);
      });

      test('should return error for empty password', () {
        expect(Validators.password(''), isNotNull);
      });

      test('should return error for short password', () {
        expect(Validators.password('ab', minLength: 6), isNotNull);
      });

      test('should accept custom min length', () {
        expect(Validators.password('abcd', minLength: 3), isNull);
      });
    });

    group('confirmPassword', () {
      test('should return null when passwords match', () {
        expect(
          Validators.confirmPassword('secret', 'secret'),
          isNull,
        );
      });

      test('should return error when passwords differ', () {
        expect(
          Validators.confirmPassword('secret', 'different'),
          isNotNull,
        );
      });

      test('should return error for empty confirmation', () {
        expect(Validators.confirmPassword('', 'secret'), isNotNull);
      });
    });

    group('minLength', () {
      test('should return null for null value (optional)', () {
        expect(Validators.minLength(null, 5), isNull);
      });

      test('should return null when length >= min', () {
        expect(Validators.minLength('hello', 3), isNull);
      });

      test('should return error when too short', () {
        expect(Validators.minLength('hi', 5), isNotNull);
      });
    });

    group('maxLength', () {
      test('should return null for null value', () {
        expect(Validators.maxLength(null, 10), isNull);
      });

      test('should return null when length <= max', () {
        expect(Validators.maxLength('hi', 5), isNull);
      });

      test('should return error when too long', () {
        expect(Validators.maxLength('hello world', 5), isNotNull);
      });
    });
  });
}
