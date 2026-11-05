import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/lang/strings_account.dart';
import 'package:stray_pets_mu/utils/validators.dart';

void main() {
  group('Validators.strongPassword', () {
    test('empty / null', () {
      expect(Validators.strongPassword(null), 'acct_pw_required');
      expect(Validators.strongPassword(''), 'acct_pw_required');
    });
    test('too short', () => expect(Validators.strongPassword('abc123'), 'acct_pw_too_short'));
    test('letters only', () => expect(Validators.strongPassword('abcdefgh'), 'acct_pw_letters_digits'));
    test('digits only', () => expect(Validators.strongPassword('12345678'), 'acct_pw_letters_digits'));
    test('same as email (case-insensitive)', () {
      expect(Validators.strongPassword('Alice99@mail.mu', email: 'alice99@mail.mu'),
          'acct_pw_same_as_email');
    });
    test('same as email local part', () {
      expect(Validators.strongPassword('alice2024', email: 'Alice2024@mail.mu'),
          'acct_pw_same_as_email');
    });
    test('acceptable password', () {
      expect(Validators.strongPassword('dodo2024', email: 'a@b.mu'), isNull);
      expect(Validators.strongPassword('Chien-Chat-77'), isNull);
    });
    test('accented letters count as letters', () {
      expect(Validators.strongPassword('éléphant9'), isNull);
    });
    test('every returned key is translated', () {
      for (final key in ['acct_pw_required', 'acct_pw_too_short', 'acct_pw_letters_digits', 'acct_pw_same_as_email']) {
        for (final lang in ['en', 'fr', 'mfe']) {
          expect(accountStrings[lang]![key], isNotNull, reason: '$lang/$key');
        }
      }
    });
  });

  group('PasswordStrength', () {
    test('flags', () {
      final s = PasswordStrength.check('abcd1234', email: 'x@y.mu');
      expect(s.longEnough, isTrue);
      expect(s.hasLetter, isTrue);
      expect(s.hasDigit, isTrue);
      expect(s.differsFromEmail, isTrue);
      expect(s.isAcceptable, isTrue);
    });
    test('no email means differsFromEmail', () {
      expect(PasswordStrength.check('abcd1234').differsFromEmail, isTrue);
    });
    test('score rises with strength', () {
      expect(PasswordStrength.check('').score, 0);
      expect(PasswordStrength.check('ab').score, 0);
      expect(PasswordStrength.check('abcdefgh').score, 1);
      expect(PasswordStrength.check('abcd1234').score, 2);
      expect(PasswordStrength.check('Abcd1234').score, 3);
      expect(PasswordStrength.check('Abcd1234!xyz').score, 4);
    });
    test('weak passwords are never acceptable', () {
      for (final pw in ['', 'short1', 'onlyletters', '1234567890']) {
        expect(PasswordStrength.check(pw).isAcceptable, isFalse, reason: pw);
      }
    });
  });
}
