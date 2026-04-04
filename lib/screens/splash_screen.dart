import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stray_pets_mu/screens/language_select_screen.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'home_screen.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final onboardingDone = prefs.getBool('onboarding_done') ?? false;
        final user = FirebaseAuth.instance.currentUser;
        if (!mounted) return;
        if (!onboardingDone) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LanguageSelectScreen()));
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => user != null ? const HomeScreen() : const LoginScreen()),
          );
        }
      } catch (e) {
        debugPrint('Navigation error: $e');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF6EC),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.pets,
                size: 100,
                color: AppTheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'MauZanimo',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rehome responsibly. Adopt locally.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textDark.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              Text('Powered by',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textDark.withOpacity(0.4),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Image.asset(
                'assets/images/jci_grand_baie.png',
                height: 140,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
