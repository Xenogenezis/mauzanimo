import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/home_screen.dart';
import 'package:stray_pets_mu/models/user_role.dart';
import 'package:flutter/gestures.dart';
import 'package:stray_pets_mu/screens/info/privacy_screen.dart';
import 'package:stray_pets_mu/utils/validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole _selectedRole = UserRole.adopter;
  bool _isLoading = false;
  String? _errorMessage;
  late final TapGestureRecognizer _privacyTap = TapGestureRecognizer()
    ..onTap = () => Navigator.push(
        context, MaterialPageRoute(builder: (_) => const PrivacyScreen()));

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordInput);
    _emailController.addListener(_onPasswordInput);
  }

  void _onPasswordInput() => setState(() {});

  @override
  void dispose() {
    _privacyTap.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final lang = context.read<LanguageProvider>().lang;
    if (_nameController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = AppStrings.get('please_fill_required_fields', lang));
      return;
    }
    final pwError = Validators.strongPassword(_passwordController.text.trim(),
        email: _emailController.text);
    if (pwError != null) {
      setState(() => _errorMessage = AppStrings.get(pwError, lang));
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _selectedRole.name,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    final textColor = context.textStrong;
    return Scaffold(
      backgroundColor: context.pageBackground,
      appBar: AppBar(title: Text(AppStrings.get('create_account', lang))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Center(child: Icon(Icons.pets, size: 64, color: AppTheme.primary)),
              const SizedBox(height: 16),
              Center(child: Text(AppStrings.get('join_mauzanimo', lang),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor))),
              const SizedBox(height: 8),
              Center(child: Text(AppStrings.get('create_an_account_to_start_adopting', lang),
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: textColor.withValues(alpha: 0.6)))),
              const SizedBox(height: 32),
              _field(_nameController, AppStrings.get('full_name', lang), Icons.person_outline),
              const SizedBox(height: 16),
              _field(_emailController, AppStrings.get('email', lang), Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _field(_phoneController, AppStrings.get('phone', lang), Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _field(_passwordController, AppStrings.get('password', lang), Icons.lock_outline, obscure: true),
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                PasswordStrengthMeter(
                  strength: PasswordStrength.check(_passwordController.text,
                      email: _emailController.text),
                  lang: lang,
                ),
              ],
              const SizedBox(height: 24),
              Text(
                AppStrings.get('i_am_a', lang),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
              ),
              const SizedBox(height: 12),
              ...selfAssignableRoles.map((role) => _RoleOption(
                role: role,
                lang: lang,
                isSelected: _selectedRole == role,
                onTap: () => setState(() => _selectedRole = role),
              )),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
              const SizedBox(height: 16),
              Text.rich(
                TextSpan(
                  text: AppStrings.get('acct_agree_prefix', lang),
                  style: TextStyle(fontSize: 13, color: textColor.withValues(alpha: 0.7)),
                  children: [
                    TextSpan(
                      text: AppStrings.get('acct_privacy_policy', lang),
                      recognizer: _privacyTap,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const TextSpan(text: '.'),
                  ],
                ),
                key: const Key('register_privacy_consent'),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(AppStrings.get('create_account', lang), style: const TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: '${AppStrings.get('already_have_account', lang)} ',
                      style: TextStyle(color: textColor.withValues(alpha: 0.6)),
                      children: [
                        TextSpan(
                          text: AppStrings.get('sign_in', lang),
                          style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
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

  Widget _field(TextEditingController c, String label, IconData icon,
    {TextInputType keyboardType = TextInputType.text, bool obscure = false}) =>
    TextField(controller: c, keyboardType: keyboardType, obscureText: obscure,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2))));
}

class _RoleOption extends StatelessWidget {
  final UserRole role;
  final String lang;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.role,
    required this.lang,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withValues(alpha: 0.1) : context.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getRoleIcon(),
              color: isSelected ? AppTheme.primary : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label('ui_role_${role.name}', role.displayName),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? context.textStrong
                          : (context.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                    ),
                  ),
                  Text(
                    _label('ui_role_${role.name}_desc', role.description),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppTheme.primary, size: 24),
          ],
        ),
      ),
    );
  }

  /// Translated role text, falling back to the English model text for
  /// roles without a ui string (they are not self-assignable).
  String _label(String key, String fallback) {
    final value = AppStrings.get(key, lang);
    return value == key ? fallback : value;
  }

  IconData _getRoleIcon() {
    return switch (role) {
      UserRole.adopter => Icons.favorite,
      UserRole.rehomer => Icons.home,
      UserRole.volunteer => Icons.volunteer_activism,
      UserRole.partner => Icons.business,
      UserRole.admin => Icons.admin_panel_settings,
      UserRole.superAdmin => Icons.supervised_user_circle,
    };
  }
}

/// Strength bar + checklist for the registration password rules.
class PasswordStrengthMeter extends StatelessWidget {
  final PasswordStrength strength;
  final String lang;

  const PasswordStrengthMeter({super.key, required this.strength, required this.lang});

  static const _labels = ['acct_pw_weak', 'acct_pw_weak', 'acct_pw_fair', 'acct_pw_good', 'acct_pw_strong'];
  static const _colors = [Colors.red, Colors.red, Colors.orange, Colors.lightGreen, Colors.green];

  @override
  Widget build(BuildContext context) {
    final score = strength.score;
    final Color color = _colors[score];
    Widget rule(bool ok, String key) => Row(children: [
          Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16, color: ok ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Expanded(child: Text(AppStrings.get(key, lang), style: const TextStyle(fontSize: 12))),
        ]);
    return Column(
      key: const Key('password_strength_meter'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score + 1) / 5,
                minHeight: 6,
                color: color,
                backgroundColor: color.withValues(alpha: 0.15),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('${AppStrings.get('acct_pw_strength', lang)}: ${AppStrings.get(_labels[score], lang)}',
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        rule(strength.longEnough, 'acct_pw_rule_length'),
        rule(strength.hasLetter && strength.hasDigit, 'acct_pw_rule_mix'),
        rule(strength.differsFromEmail, 'acct_pw_rule_email'),
      ],
    );
  }
}
