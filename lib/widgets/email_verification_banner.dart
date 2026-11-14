import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../lang/app_strings.dart';
import '../providers/auth_provider.dart';
import '../providers/language_provider.dart';
import '../screens/auth/verify_email_screen.dart';

/// Strip shown on the home screen while the signed-in account still has to
/// confirm its email address. Takes no space otherwise.
class EmailVerificationBanner extends StatelessWidget {
  const EmailVerificationBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!context.watch<AuthProvider>().needsEmailVerification) return const SizedBox.shrink();
    final lang = context.watch<LanguageProvider>().lang;

    return Material(
      color: Colors.amber.shade700,
      child: InkWell(
        key: const ValueKey('verify-email-banner'),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VerifyEmailScreen())),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(children: [
            const Icon(Icons.mark_email_unread_outlined, color: Colors.black87, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                AppStrings.get('verify_banner', lang),
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              AppStrings.get('verify_banner_action', lang),
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.chevron_right, color: Colors.black87, size: 20),
          ]),
        ),
      ),
    );
  }
}
