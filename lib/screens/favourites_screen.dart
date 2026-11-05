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
import 'package:stray_pets_mu/providers/recently_viewed_provider.dart';
import 'package:stray_pets_mu/widgets/app_image.dart';
import 'package:stray_pets_mu/utils/responsive.dart';

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
        header: const _RecentlyViewedStrip(),
      );
    }
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _RecentlyViewedStrip(),
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
                      return LayoutBuilder(builder: (context, constraints) => GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridColumnsForWidth(constraints.maxWidth - 32),
                          crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75),
                        itemCount: favPets.length,
                        itemBuilder: (context, index) {
                          final pet = favPets[index].data() as Map<String, dynamic>;
                          final petId = favPets[index].id;
                          return PetCard(
                            pet: pet, petId: petId,
                            onTap: () => Navigator.push(context,
                              MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet, petId: petId))));
                        },
                      ));
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
  final Widget? header;

  const _LoginPrompt({required this.message, required this.icon, this.header});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().lang;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (header != null) header!,
            Expanded(
              child: Center(
                child: SingleChildScrollView(
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
          ],
        ),
      ),
    );
  }
}

/// Horizontal strip of the pets this device viewed most recently.
/// Hidden when there is nothing (left) to show.
class _RecentlyViewedStrip extends StatefulWidget {
  const _RecentlyViewedStrip();

  @override
  State<_RecentlyViewedStrip> createState() => _RecentlyViewedStripState();
}

class _RecentlyViewedStripState extends State<_RecentlyViewedStrip> {
  /// Pet data by id; a null value means the pet no longer exists.
  final Map<String, Map<String, dynamic>?> _pets = {};
  bool _fetching = false;

  /// Fetches only the ids not seen yet (whereIn allows up to 10 values,
  /// which matches the recently viewed cap).
  void _fetchMissing(List<String> ids) {
    if (_fetching) return;
    final missing = ids.where((id) => !_pets.containsKey(id)).take(10).toList();
    if (missing.isEmpty) return;
    _fetching = true;
    FirebaseFirestore.instance
        .collection('pets')
        .where(FieldPath.documentId, whereIn: missing)
        .get()
        .then((snapshot) {
      if (!mounted) return;
      setState(() {
        for (final id in missing) {
          _pets[id] = null;
        }
        for (final doc in snapshot.docs) {
          _pets[doc.id] = doc.data();
        }
        _fetching = false;
      });
    }).catchError((Object _) {
      // Leave the section hidden; it will retry the next time ids change.
      _fetching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final RecentlyViewedProvider recent;
    try {
      recent = context.watch<RecentlyViewedProvider>();
    } on ProviderNotFoundException {
      return const SizedBox.shrink();
    }
    final lang = context.watch<LanguageProvider>().lang;
    final ids = recent.ids;
    _fetchMissing(ids);
    final pets = [
      for (final id in ids)
        if (_pets[id] != null) MapEntry(id, _pets[id]!),
    ];
    if (pets.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(AppStrings.get('recently_viewed', lang),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                ),
                TextButton(
                  onPressed: recent.clear,
                  child: Text(AppStrings.get('recently_viewed_clear', lang)),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: pets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final petId = pets[index].key;
                final pet = pets[index].value;
                final name = (pet['name'] as String?)?.trim() ?? '';
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet, petId: petId))),
                  child: SizedBox(
                    width: 84,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppImage(pet['imageUrl'] as String?,
                              width: 84, height: 84, decodeWidth: 84),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(name.isEmpty ? AppStrings.get('recently_viewed_unnamed', lang) : name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textDark)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
