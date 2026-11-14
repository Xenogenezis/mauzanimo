import 'package:firebase_auth/firebase_auth.dart';

/// Sign-in methods whose provider has already confirmed who the person is,
/// so no email verification is asked. Mirrors `isVerified()` in
/// firestore.rules.
const List<String> providerVerifiedSignIns = ['phone', 'google.com', 'facebook.com'];

/// Whether an account still has to confirm its email address.
///
/// Only email + password accounts are asked: anyone can type someone else's
/// address there. [providerIds] are the account's linked sign-in methods
/// (`User.providerData`).
bool needsEmailVerification({required bool emailVerified, required Iterable<String> providerIds}) {
  if (emailVerified) return false;
  return !providerIds.any(providerVerifiedSignIns.contains);
}

/// [needsEmailVerification] for a Firebase user; false when signed out.
bool userNeedsEmailVerification(User? user) =>
    user != null &&
    needsEmailVerification(
      emailVerified: user.emailVerified,
      providerIds: user.providerData.map((p) => p.providerId),
    );

/// Sends (or re-sends) the verification link. Returns false when it could
/// not be sent (offline, or Firebase's rate limit).
Future<bool> sendVerificationEmail(User user, {String? languageCode}) async {
  try {
    if (languageCode != null) {
      // Kreol has no Firebase email template; French is the closest.
      await FirebaseAuth.instance.setLanguageCode(languageCode == 'mfe' ? 'fr' : languageCode);
    }
    await user.sendEmailVerification();
    return true;
  } catch (_) {
    return false;
  }
}

/// Re-reads the account from Firebase after the person says they clicked the
/// link. Returns true once the email is verified. The ID token is refreshed
/// too, because the Firestore rules read `email_verified` from it.
Future<bool> refreshEmailVerified() async {
  final auth = FirebaseAuth.instance;
  try {
    await auth.currentUser?.reload();
    final user = auth.currentUser;
    if (user == null || userNeedsEmailVerification(user)) return false;
    await user.getIdToken(true);
    return true;
  } catch (_) {
    return false;
  }
}
