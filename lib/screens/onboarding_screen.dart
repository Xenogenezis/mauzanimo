import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/lang/language_provider.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> _pages(String lang) => [
    {
      'icon': Icons.pets,
      'color': AppTheme.primary,
      'title': lang == 'fr' ? 'Bienvenue sur MauZanimo' : 'Welcome to MauZanimo',
      'subtitle': lang == 'fr'
        ? 'Connecter les animaux errants avec des foyers aimants a travers Maurice.'
        : 'Helping owners rehome responsibly and families adopt locally across Mauritius.',
    },
    {
      'icon': Icons.search,
      'color': Colors.orange,
      'title': lang == 'fr' ? 'Trouver un nouveau foyer' : 'Find a New Home',
      'subtitle': lang == 'fr'
        ? 'Parcourez les chiens, chats et autres animaux cherchant un foyer.'
        : 'Browse pets listed by caring owners looking for a loving new home.',
    },
    {
      'icon': Icons.favorite_outline,
      'color': Colors.red,
      'title': lang == 'fr' ? 'Adoptez en confiance' : 'Adopt with Confidence',
      'subtitle': lang == 'fr'
        ? 'Soumettez une demande et notre equipe vous guidera pas a pas.'
        : 'Apply to adopt and connect directly with the pet owner. Simple, safe and transparent.',
    },
    {
      'icon': Icons.volunteer_activism_outlined,
      'color': Colors.purple,
      'title': lang == 'fr' ? 'Faites partie du changement' : 'Be Part of the Change',
      'subtitle': lang == 'fr'
        ? 'Listez votre animal, faites du benevolat, donnez ou devenez partenaire.'
        : 'List your pet for rehoming, volunteer, donate or become a partner.',
    },
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    final pages = _pages(lang);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: Text(lang == 'fr' ? 'Passer' : 'Skip', style: const TextStyle(color: Colors.grey)),
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
                            color: (page['color'] as Color).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page['icon'] as IconData, size: 80, color: page['color'] as Color),
                        ),
                        const SizedBox(height: 40),
                        Text(page['title'] as String,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        const SizedBox(height: 16),
                        Text(page['subtitle'] as String,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: AppTheme.textDark.withOpacity(0.6), height: 1.6)),
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
                          ? (lang == 'fr' ? 'Suivant' : 'Next')
                          : (lang == 'fr' ? 'Commencer' : 'Get Started'),
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
