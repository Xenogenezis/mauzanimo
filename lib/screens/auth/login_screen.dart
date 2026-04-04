import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/screens/home_screen.dart';
import 'package:stray_pets_mu/screens/admin/admin_dashboard.dart';
import 'package:stray_pets_mu/screens/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Admin access: Tap icon 8 times
  int _tapCount = 0;
  DateTime? _firstTapTime;
  static const int _requiredTaps = 8;
  static const Duration _tapWindow = Duration(seconds: 3);

  void _handleIconTap() {
    final now = DateTime.now();

    // Reset if outside time window
    if (_firstTapTime != null && now.difference(_firstTapTime!) > _tapWindow) {
      _tapCount = 0;
      _firstTapTime = null;
    }

    // Start new sequence
    if (_tapCount == 0) {
      _firstTapTime = now;
    }

    setState(() => _tapCount++);

    // Check if reached required taps
    if (_tapCount >= _requiredTaps) {
      _tapCount = 0;
      _firstTapTime = null;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    }
  }

  Future<void> _forgotPassword(BuildContext context, String lang) async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang == 'fr' ? 'Entrez votre email dabord' : 'Please enter your email address first')));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang == 'fr' ? 'Email de reinitialisation envoye!' : 'Password reset email sent!')));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? '')));
    }
  }

  Future<void> _login(String lang) async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              GestureDetector(
                onTap: _handleIconTap,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: _tapCount > 0
                        ? AppTheme.primary.withValues(alpha: 0.1 * (_tapCount / _requiredTaps).clamp(0.1, 1.0))
                        : Colors.transparent,
                  ),
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.pets, size: 80, color: AppTheme.primary),
                        if (_tapCount > 0)
                          Positioned(
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_tapCount/$_requiredTaps',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(child: Text('MauZanimo',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
              const SizedBox(height: 8),
              Center(child: Text(lang == 'fr' ? 'Connectez-vous pour continuer' : 'Sign in to continue',
                style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.6)))),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: AppStrings.get('email', lang),
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: AppStrings.get('password', lang),
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => _forgotPassword(context, lang),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(AppStrings.get('forgot_password', lang),
                    style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w500, fontSize: 13)),
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _login(lang),
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppStrings.get('sign_in', lang)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterScreen())),
                  child: RichText(
                    text: TextSpan(
                      text: '${AppStrings.get('no_account', lang)} ',
                      style: TextStyle(color: AppTheme.textDark.withOpacity(0.6)),
                      children: [
                        TextSpan(
                          text: AppStrings.get('sign_up', lang),
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
