import 'package:flutter_test/flutter_test.dart';
import 'package:stray_pets_mu/lang/strings_account.dart';
import 'package:stray_pets_mu/utils/email_verification.dart';

void main() {
  group('needsEmailVerification', () {
    test('an unverified email + password account must verify', () {
      expect(needsEmailVerification(emailVerified: false, providerIds: ['password']), isTrue);
    });

    test('a verified email does not', () {
      expect(needsEmailVerification(emailVerified: true, providerIds: ['password']), isFalse);
    });

    test('phone, Google and Facebook sign-ins are verified by their provider', () {
      for (final p in ['phone', 'google.com', 'facebook.com']) {
        expect(needsEmailVerification(emailVerified: false, providerIds: [p]), isFalse, reason: p);
      }
    });

    test('a password account with a linked phone number is verified', () {
      expect(needsEmailVerification(emailVerified: false, providerIds: ['password', 'phone']), isFalse);
    });

    test('unknown or missing providers still have to verify', () {
      expect(needsEmailVerification(emailVerified: false, providerIds: const []), isTrue);
      expect(needsEmailVerification(emailVerified: false, providerIds: ['anonymous']), isTrue);
    });

    test('the provider list matches the Firestore rule', () {
      expect(providerVerifiedSignIns, ['phone', 'google.com', 'facebook.com']);
    });
  });

  test('verification strings exist in en, fr and mfe with their placeholders', () {
    final keys = accountStrings['en']!.keys.where((k) => k.startsWith('verify_')).toSet();
    expect(keys.length, greaterThanOrEqualTo(13));
    for (final lang in ['en', 'fr', 'mfe']) {
      for (final k in keys) {
        expect(accountStrings[lang]![k], isNotEmpty, reason: '$lang $k');
      }
      expect(accountStrings[lang]!['verify_body'], contains('{email}'), reason: lang);
      expect(accountStrings[lang]!['verify_resend_wait'], contains('{s}'), reason: lang);
    }
  });
}
