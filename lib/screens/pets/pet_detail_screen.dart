import 'package:flutter/material.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/adoption/adoption_inquiry_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetDetailScreen extends StatelessWidget {
  final Map<String, dynamic> pet;
  final String petId;
  const PetDetailScreen({super.key, required this.pet, required this.petId});

  Future<void> _toggleFavourite() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final ref = FirebaseFirestore.instance.collection('favourites');
    final existing = await ref.where('userId', isEqualTo: user.uid).where('petId', isEqualTo: petId).get();
    if (existing.docs.isEmpty) {
      await ref.add({'userId': user.uid, 'petId': petId, 'createdAt': FieldValue.serverTimestamp()});
    } else {
      await existing.docs.first.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300, pinned: true,
            actions: [
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('favourites')
                  .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                  .where('petId', isEqualTo: petId).snapshots(),
                builder: (context, snapshot) {
                  final isFav = snapshot.data?.docs.isNotEmpty ?? false;
                  return IconButton(
                    icon: Icon(isFav ? Icons.favorite : Icons.favorite_outline,
                      color: isFav ? Colors.red : Colors.white),
                    onPressed: _toggleFavourite,
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: pet['imageUrl'] != null
                ? Image.network(pet['imageUrl'], fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => _placeholder())
                : _placeholder(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pet['name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: _statusColor(pet['status']), borderRadius: BorderRadius.circular(20)),
                        child: Text(pet['status'] ?? 'Available',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(pet['location'] ?? 'Mauritius', style: const TextStyle(color: Colors.grey, fontSize: 14)),
                  ]),
                  const SizedBox(height: 20),
                  Row(children: [
                    _chip(Icons.category_outlined, pet['type'] ?? 'Pet'),
                    const SizedBox(width: 10),
                    _chip(Icons.cake_outlined, pet['age'] ?? 'Unknown'),
                    const SizedBox(width: 10),
                    _chip(Icons.male_outlined, pet['gender'] ?? 'Unknown'),
                  ]),
                  const SizedBox(height: 24),
                  Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  Text(pet['description'] ?? 'No description available.',
                    style: TextStyle(fontSize: 14, color: AppTheme.textDark.withOpacity(0.7), height: 1.6)),
                  const SizedBox(height: 24),
                  Text('Health Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 8),
                  Row(children: [
                    _healthChip('Vaccinated', pet['vaccinated'] == true),
                    const SizedBox(width: 10),
                    _healthChip('Sterilized', pet['sterilized'] == true),
                      const SizedBox(width: 10),
                    _healthChip('Dewormed', pet['dewormed'] == true),
                      
                  ]),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: pet['status'] == 'adopted' ? null : () =>
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => AdoptionInquiryScreen(pet: pet, petId: petId))),
                      child: Text('Start Adoption Process', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final phone = pet['contact'] ?? '';
                        final name = pet['name'] ?? 'this pet';
                        final message = 'Hi, I am interested in adopting ' + name + ' from MauZanimo!';
                        final url = 'https://wa.me/' + phone.replaceAll(' ', '') + '?text=' + Uri.encodeComponent(message);
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                        }
                      },
                      icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                      label: Text('Chat on WhatsApp', style: TextStyle(color: Color(0xFF25D366))),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF25D366)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() => Container(color: AppTheme.lightGrey,
    child: Center(child: Icon(Icons.pets, size: 80, color: AppTheme.primary)));
  Widget _chip(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppTheme.lightGrey, borderRadius: BorderRadius.circular(20)),
    child: Row(children: [Icon(icon, size: 14, color: AppTheme.primary), const SizedBox(width: 4),
      Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))]));
  Widget _healthChip(String label, bool isTrue) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: isTrue ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20)),
    child: Row(children: [
      Icon(isTrue ? Icons.check_circle_outline : Icons.cancel_outlined,
        size: 14, color: isTrue ? Colors.green : Colors.red),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 12, color: isTrue ? Colors.green : Colors.red))]));
  Color _statusColor(String? s) {
    if (s == 'adopted') return Colors.red;
    if (s == 'pending') return Colors.orange;
    return Colors.green;
  }
}
