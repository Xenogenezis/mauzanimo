import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/auth_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';
import 'package:stray_pets_mu/screens/home_screen.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/utils/email_verification.dart';

/// Seconds to wait before the verification email can be sent again.
const int verifyResendCooldownSeconds = 60;

/// Shown to an email + password account that has not confirmed its address
/// yet: explains the link that was emailed, lets them re-send it, and checks
/// whether they have clicked it.
///
/// [replaceWithHome] is for the sign-up and login flows, where this screen
/// stands in for the home screen; otherwise it simply closes when done.
class VerifyEmailScreen extends StatefulWidget {
  final bool replaceWithHome;

  /// Start with the resend button cooling down (an email was just sent).
  final bool justSent;

  const VerifyEmailScreen({super.key, this.replaceWithHome = false, this.justSent = false});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  Timer? _timer;
  int _cooldown = 0;
  bool _checking = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    if (widget.justSent) _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _t(String key) => AppStrings.get(key, context.read<LanguageProvider>().lang);

  void _snack(String key) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t(key))));
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = verifyResendCooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _resend() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _sending = true);
    final ok = await sendVerificationEmail(user, languageCode: context.read<LanguageProvider>().lang);
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      _startCooldown();
      _snack('verify_sent');
    } else {
      _snack('verify_send_failed');
    }
  }

  Future<void> _check() async {
    setState(() => _checking = true);
    final verified = await refreshEmailVerified();
    if (!mounted) return;
    setState(() => _checking = false);
    if (!verified) {
      _snack('verify_not_yet');
      return;
    }
    // Screens that watch the auth state pick up the verified account.
    context.read<AuthProvider>().refreshUser();
    _snack('verify_success');
    if (widget.replaceWithHome) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      Navigator.pop(context, true);
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthProvider>().signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    String t(String key) => AppStrings.get(key, lang);
    final email = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(t('verify_title'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            const Icon(Icons.mark_email_unread_outlined, size: 80, color: AppTheme.primary),
            const SizedBox(height: 24),
            Text(
              t('verify_body').replaceAll('{email}', email),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5, color: context.textStrong),
            ),
            const SizedBox(height: 12),
            Text(
              t('verify_spam'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              key: const ValueKey('verify-check'),
              onPressed: _checking ? null : _check,
              child: _checking
                  ? const SizedBox(
                      height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(t('verify_done')),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              key: const ValueKey('verify-resend'),
              onPressed: _sending || _cooldown > 0 ? null : _resend,
              child: Text(_cooldown > 0
                  ? t('verify_resend_wait').replaceAll('{s}', '$_cooldown')
                  : t('verify_resend')),
            ),
            const SizedBox(height: 24),
            TextButton(
              key: const ValueKey('verify-sign-out'),
              onPressed: _signOut,
              child: Text(t('verify_sign_out')),
            ),
          ],
        ),
      ),
    );
  }
}
