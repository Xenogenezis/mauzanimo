import 'package:flutter/material.dart';
import '../repositories/pet_repository.dart';
import '../models/pet.dart';
import '../utils/result.dart';

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
      final result = _petRepository.getFavoritePetIds(_userId!);
      result.when(
        success: (stream) {
          stream.listen((ids) {
            _favoriteIds = ids;
            notifyListeners();
          });
        },
        failure: (message) {
          _error = message;
          notifyListeners();
        },
      );

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

    final result = await _petRepository.getFavoritePets(_userId!);
    result.when(
      success: (pets) {
        _favoritePets = pets;
      },
      failure: (message) {
        _error = message;
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String petId) async {
    if (_userId == null) {
      _error = 'Please sign in to save favorites';
      notifyListeners();
      return;
    }

    final result = await _petRepository.toggleFavorite(_userId!, petId);
    result.when(
      success: (_) {
        // State updates via stream listener
      },
      failure: (message) {
        _error = message;
        notifyListeners();
      },
    );
  }

  // Get stream of favorite status for a specific pet
  Stream<bool> isPetFavoritedStream(String petId) {
    if (_userId == null) return Stream.value(false);
    final result = _petRepository.isPetFavorited(_userId!, petId);
    return result.when(
      success: (stream) => stream,
      failure: (message) {
        _error = message;
        return Stream.value(false);
      },
    );
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
