import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/providers/auth_provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';

class AuthGuard {
  static void requireAuth(BuildContext context, VoidCallback onAuthenticated) {
    final authProvider = context.read<AuthProvider>();
    if (authProvider.isAuthenticated) {
      onAuthenticated();
      return;
    }

    final lang = context.read<LanguageProvider>().lang;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get('sign_in_to_continue', lang)),
        content: Text(AppStrings.get('login_to_continue', lang)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppStrings.get('cancel', lang)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: Text(AppStrings.get('sign_in', lang)),
          ),
        ],
      ),
    );
  }
}
