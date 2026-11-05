import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/pets/pet_list_screen.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';
import 'package:stray_pets_mu/screens/profile_screen.dart';
import 'package:stray_pets_mu/screens/favourites_screen.dart';
import 'package:stray_pets_mu/screens/pets/upload_pet_screen.dart';
import 'package:stray_pets_mu/screens/drawer_menu.dart';
import 'package:stray_pets_mu/providers/auth_provider.dart';
import 'package:stray_pets_mu/widgets/auth_guard.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';
import 'package:stray_pets_mu/widgets/adaptive_nav_scaffold.dart';
import 'package:stray_pets_mu/screens/notifications/notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}
class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [const PetListScreen(), const FavouritesScreen(), const ProfileScreen()];
  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return AdaptiveNavScaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Row(children: [
          Icon(Icons.pets, color: Colors.white),
          SizedBox(width: 8),
          Text('MauZanimo', style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          const NotificationBell(),
          Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (!authProvider.isAuthenticated) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.logout),
                tooltip: AppStrings.get('sign_out', lang),
                onPressed: () async {
                  await authProvider.signOut();
                  if (!context.mounted) return;
                  Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
                },
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      floatingActionButton: _currentIndex == 0 ? FloatingActionButton.extended(
        onPressed: () => AuthGuard.requireAuth(context, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const UploadPetScreen()));
        }),
        backgroundColor: AppTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(AppStrings.get('list_pet', lang), style: const TextStyle(color: Colors.white)),
      ) : null,
      currentIndex: _currentIndex,
      onDestinationSelected: (index) => setState(() => _currentIndex = index),
      destinations: [
        AdaptiveNavDestination(icon: Icons.pets, label: AppStrings.get('pets', lang)),
        AdaptiveNavDestination(icon: Icons.favorite_outline, label: AppStrings.get('saved', lang)),
        AdaptiveNavDestination(icon: Icons.person_outline, label: AppStrings.get('profile', lang)),
      ],
    );
  }
}
