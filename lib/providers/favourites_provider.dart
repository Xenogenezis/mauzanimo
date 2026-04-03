import 'package:flutter/material.dart';
import '../repositories/pet_repository.dart';
import '../models/pet.dart';

class FavouritesProvider extends ChangeNotifier {
  final PetRepository _petRepository;
  final String? _userId;

  List<String> _favoriteIds = [];
  List<Pet> _favoritePets = [];
  bool _isLoading = false;
  String? _error;

  FavouritesProvider(this._petRepository, this._userId) {
    if (_userId != null) {
      // Listen to favorite IDs stream
      _petRepository.getFavoritePetIds(_userId!).listen((ids) {
        _favoriteIds = ids;
        notifyListeners();
      });

      // Load favorite pets
      _loadFavoritePets();
    }
  }

  // Getters
  List<String> get favoriteIds => _favoriteIds;
  List<Pet> get favoritePets => _favoritePets;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _userId != null;

  // Check if a pet is favorited
  bool isPetFavorited(String petId) => _favoriteIds.contains(petId);

  // Load favorite pets
  Future<void> _loadFavoritePets() async {
    if (_userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _favoritePets = await _petRepository.getFavoritePets(_userId!);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String petId) async {
    if (_userId == null) {
      _error = 'Please sign in to save favorites';
      notifyListeners();
      return;
    }

    try {
      await _petRepository.toggleFavorite(_userId!, petId);
      // State updates via stream listener
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get stream of favorite status for a specific pet
  Stream<bool> isPetFavoritedStream(String petId) {
    if (_userId == null) return Stream.value(false);
    return _petRepository.isPetFavorited(_userId!, petId);
  }

  // Refresh favorites
  Future<void> refresh() async {
    await _loadFavoritePets();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
