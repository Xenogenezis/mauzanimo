import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/theme/adaptive_colors.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  static const List<(IconData, Color)> _pageStyles = [
    (Icons.pets, AppTheme.primary),
    (Icons.search, Colors.orange),
    (Icons.favorite_outline, Colors.red),
    (Icons.volunteer_activism_outlined, Colors.purple),
  ];

  List<Map<String, dynamic>> _pages(String lang) => [
    for (var i = 0; i < _pageStyles.length; i++)
      {
        'icon': _pageStyles[i].$1,
        'color': _pageStyles[i].$2,
        'title': AppStrings.get('ui_onb_title_${i + 1}', lang),
        'subtitle': AppStrings.get('ui_onb_body_${i + 1}', lang),
      },
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final pages = _pages(lang);
    final textColor = context.textStrong;
    return Scaffold(
      backgroundColor: context.pageBackground,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(AppStrings.get('ui_skip', lang), style: const TextStyle(color: Colors.grey)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: pages.length,
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page['icon'] as IconData, size: 80, color: page['color'] as Color),
                        ),
                        const SizedBox(height: 40),
                        Text(page['title'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                        const SizedBox(height: 16),
                        Text(page['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: textColor.withValues(alpha: 0.6), height: 1.6)),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? AppTheme.primary : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < pages.length - 1) {
                          _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                        } else {
                          _finish();
                        }
                      },
                      child: Text(
                        _currentPage < pages.length - 1
                          ? AppStrings.get('ui_next', lang)
                          : AppStrings.get('ui_get_started', lang),
                        style: const TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
