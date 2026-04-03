const fs = require('fs');
fs.writeFileSync('lib/screens/favourites_screen.dart', `import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/pets/pet_card.dart';
import 'package:stray_pets_mu/screens/pets/pet_detail_screen.dart';

class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('Saved Pets',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('favourites').where('userId', isEqualTo: user?.uid).snapshots(),
                builder: (context, favSnapshot) {
                  if (favSnapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                  final docs = favSnapshot.data?.docs ?? [];
                  if (docs.isEmpty)
                    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.favorite_outline, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      const Text('No saved pets yet', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      const Text('Tap the heart on any pet to save them here.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    ]));
                  final petIds = docs.map((d) => (d.data() as Map<String, dynamic>)['petId'] as String).toList();
                  return FutureBuilder<QuerySnapshot>(
                    future: FirebaseFirestore.instance.collection('pets').get(),
                    builder: (context, petSnapshot) {
                      if (petSnapshot.data == null)
                        return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                      final favPets = petSnapshot.data!.docs.where((d) => petIds.contains(d.id)).toList();
                      if (favPets.isEmpty)
                        return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.favorite_outline, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No saved pets yet', style: TextStyle(color: Colors.grey)),
                        ]));
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
`);
console.log('Done!');
