import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stray_pets_mu/theme/app_theme.dart';
import 'package:stray_pets_mu/screens/pets/pet_card.dart';
import 'package:stray_pets_mu/screens/pets/pet_detail_screen.dart';
import 'package:provider/provider.dart';
import 'package:stray_pets_mu/providers/language_provider.dart';
import 'package:stray_pets_mu/lang/app_strings.dart';

class PetListScreen extends StatefulWidget {
  const PetListScreen({super.key});
  @override
  State<PetListScreen> createState() => _PetListScreenState();
}

class _PetListScreenState extends State<PetListScreen> {
  String _selectedFilter = 'All';
  String _searchQuery = '';
  bool _isSearching = false;
  List<DocumentSnapshot> _searchResults = [];

  List<String> get _filters => ['All', 'Dogs', 'Cats', 'Others'];

  /// Perform server-side search using Firestore queries
  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      // Firestore doesn't support native full-text search
      // We use a prefix-based search with orderBy for better performance
      final queryLower = query.toLowerCase();
      final queryUpper = queryLower.substring(0, queryLower.length - 1) +
          String.fromCharCode(queryLower.codeUnitAt(queryLower.length - 1) + 1);

      // Search by name (prefix match)
      final nameQuery = await FirebaseFirestore.instance
          .collection('pets')
          .where('name', isGreaterThanOrEqualTo: queryLower)
          .where('name', isLessThan: queryUpper)
          .limit(20)
          .get();

      // Search by location (prefix match)
      final locationQuery = await FirebaseFirestore.instance
          .collection('pets')
          .where('location', isGreaterThanOrEqualTo: queryLower)
          .where('location', isLessThan: queryUpper)
          .limit(20)
          .get();

      // Combine results and remove duplicates
      final allDocs = {...nameQuery.docs, ...locationQuery.docs}.toList();

      setState(() {
        _searchResults = allDocs;
        _isSearching = false;
      });
    } catch (e) {
      setState(() => _isSearching = false);
      // Fall back to showing all pets
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed. Showing all pets.')),
      );
    }
  }

  Stream<QuerySnapshot>? get _petStream {
    // If searching with results, return null to use the search results instead
    if (_searchQuery.isNotEmpty) {
      return null;
    }

    // Server-side filtering with where clauses
    if (_selectedFilter == 'All') {
      return FirebaseFirestore.instance
          .collection('pets')
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      return FirebaseFirestore.instance
          .collection('pets')
          .where('type', isEqualTo: _selectedFilter.toLowerCase())
          .orderBy('createdAt', descending: true)
          .snapshots();
    }
  }

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
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.get('find_companion', lang),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                AppStrings.get('give_home', lang),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  onChanged: (val) {
                    setState(() => _searchQuery = val.toLowerCase());
                    // Debounce search
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (mounted && _searchQuery == val.toLowerCase()) {
                        _performSearch(_searchQuery);
                      }
                    });
                  },
                  decoration: InputDecoration(
                    hintText: AppStrings.get('search_pets', lang),
                    border: InputBorder.none,
                    icon: Icon(Icons.search, color: AppTheme.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchResults = [];
                              });
                            },
                          )
                        : null,
                  ),
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
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter);
                    }
                  },
                  selectedColor: AppTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textDark,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppTheme.lightGrey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _searchQuery.isNotEmpty
                  ? _buildSearchResults(lang)
                  : _buildPetStream(lang),
        ),
      ],
    );
  }

  Widget _buildSearchResults(String lang) {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              AppStrings.get('no_pets', lang),
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final pet = _searchResults[index].data() as Map<String, dynamic>;
        final petId = _searchResults[index].id;
        return PetCard(
          pet: pet,
          petId: petId,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PetDetailScreen(pet: pet, petId: petId),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPetStream(String lang) {
    return StreamBuilder<QuerySnapshot>(
      stream: _petStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  AppStrings.get('no_pets', lang),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final pet = snapshot.data!.docs[index].data() as Map<String, dynamic>;
            final petId = snapshot.data!.docs[index].id;
            return PetCard(
              pet: pet,
              petId: petId,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PetDetailScreen(pet: pet, petId: petId),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
