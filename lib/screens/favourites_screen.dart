import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/pets/pet_card.dart';
import 'package:stray_pets_mu/screens/pets/pet_detail_screen.dart';
import 'package:stray_pets_mu/screens/auth/login_screen.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  Stream<QuerySnapshot>? _stream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _stream = FirebaseFirestore.instance
          .collection('favourites')
          .where('userId', isEqualTo: user.uid)
          .snapshots();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lang = context.watch<LanguageProvider>().lang;
    if (user == null) {
      return _LoginPrompt(
        message: AppStrings.get('saved_login_prompt', lang),
        icon: Icons.favorite_outline,
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(AppStrings.get('saved_pets', lang),
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _stream,
                builder: (context, favSnapshot) {
                  if (favSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  }
                  final docs = favSnapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.favorite_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(AppStrings.get('no_saved', lang), style: const TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(AppStrings.get('no_saved_hint', lang), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ]));
                  }
                  final petIds = docs.map((d) => (d.data() as Map<String, dynamic>)['petId'] as String).toList();
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('pets').get(),
                    builder: (context, petSnapshot) {
                      if (petSnapshot.data == null) {
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                      }
                      final favPets = petSnapshot.data!.docs.where((d) => petIds.contains(d.id)).toList();
                      if (favPets.isEmpty) {
                        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.favorite_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No saved pets yet', style: TextStyle(color: Colors.grey)),
                        ]));
                      }
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75),
                        itemCount: favPets.length,
                        itemBuilder: (context, index) {
                          final pet = favPets[index].data() as Map<String, dynamic>;
                          final petId = favPets[index].id;
                          return PetCard(
                            pet: pet, petId: petId,
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet, petId: petId))));
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginPrompt extends StatelessWidget {
  final String message;
  final IconData icon;

  const _LoginPrompt({required this.message, required this.icon});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  ),
                  child: Text(AppStrings.get('sign_in', lang)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
