import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/pets/pet_card.dart';
import 'package:stray_pets_mu/screens/pets/pet_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/lang/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});
  @override
  State<PetListScreen> createState() => _PetListScreenState();
}
class _PetListScreenState extends State<PetListScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  List<String> get _filters => ['All', 'Dogs', 'Cats', 'Others'];
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context).lang;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.get('find_companion', lang), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(AppStrings.get('give_home', lang), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                  decoration: InputDecoration(hintText: AppStrings.get('search_pets', lang), border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppTheme.primary)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = filter == _selectedFilter;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilter = filter),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primary : AppTheme.lightGrey,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(filter, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textDark, fontWeight: FontWeight.w500)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _selectedFilter == 'All'
              ? FirebaseFirestore.instance.collection('pets').snapshots()
              : FirebaseFirestore.instance.collection('pets').where('type', isEqualTo: _selectedFilter.toLowerCase()).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator(color: AppTheme.primary));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(AppStrings.get('no_pets', lang), style: const TextStyle(color: Colors.grey)),
                ]));
              final pets = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final location = (data['location'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || location.contains(_searchQuery);
              }).toList();
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75),
                itemCount: pets.length,
                itemBuilder: (context, index) {
                  final pet = pets[index].data() as Map<String, dynamic>;
                  final petId = pets[index].id;
                  return PetCard(pet: pet, petId: petId,
                    onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => PetDetailScreen(pet: pet, petId: petId))));
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
