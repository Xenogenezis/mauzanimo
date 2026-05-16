import 'dart:async';
import 'package:flutter/material.dart';
import '../repositories/pet_repository.dart';
import '../models/pet.dart';
import '../models/pet_preferences.dart';
import '../utils/result.dart';

class PetProvider extends ChangeNotifier {
  final PetRepository _petRepository;

  List<Pet> _pets = [];
  List<Pet> _filteredPets = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  int _currentLimit = 20;
  StreamSubscription<List<Pet>>? _subscription;
  PetPreferences? _preferences;

  PetProvider(this._petRepository) {
    _setupStream();
  }

  // Getters
  List<Pet> get pets => _filteredPets;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;

  // Available filters
  List<String> get filters => ['All', 'Dogs', 'Cats', 'Others'];

  void _setupStream() {
    _subscription?.cancel();
    final result = _petRepository.getPetsStream(
      typeFilter: _selectedFilter,
      limit: _currentLimit,
    );
    result.when(
      success: (stream) {
        _subscription = stream.listen((pets) {
          _pets = pets;
          _hasMore = pets.length >= _currentLimit;
          _applyFilters();
        });
      },
      failure: (message) {
        _error = message;
        notifyListeners();
      },
    );
  }

  void _applyFilters() {
    var result = _pets;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((pet) {
        return pet.name.toLowerCase().contains(query) ||
            pet.location.toLowerCase().contains(query) ||
            pet.description.toLowerCase().contains(query);
      }).toList();
    }

    if (_preferences != null) {
      final prefs = _preferences!;
      if (prefs.types.isNotEmpty) {
        result = result.where((p) => prefs.types.contains(p.type.toLowerCase())).toList();
      }
      if (prefs.gender != null && prefs.gender != 'any') {
        result = result.where((p) => p.gender.toLowerCase() == prefs.gender!.toLowerCase()).toList();
      }
      if (prefs.preferredLocation != null && prefs.preferredLocation!.isNotEmpty) {
        result = result.where((p) => p.location.toLowerCase().contains(prefs.preferredLocation!.toLowerCase())).toList();
      }
      if (prefs.ageRange != 'any') {
        result = result.where((p) => _matchesAgeRange(p.age, prefs.ageRange)).toList();
      }
    }

    _filteredPets = result;
    notifyListeners();
  }

  void setPreferences(PetPreferences? prefs) {
    _preferences = prefs;
    _applyFilters();
  }

  bool _matchesAgeRange(String petAge, String range) {
    final years = int.tryParse(petAge.replaceAll(RegExp(r'[^0-9]'), ''));
    if (years == null) return true;
    switch (range) {
      case 'young':
        return years <= 1;
      case 'adult':
        return years > 1 && years <= 7;
      case 'senior':
        return years > 7;
      default:
        return true;
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setFilter(String filter) {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    _currentLimit = 20;
    _hasMore = true;
    _setupStream();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    _currentLimit += 20;
    _setupStream();

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<bool> addPet(Pet pet) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _petRepository.addPet(pet);
    final success = result.when(
      success: (_) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (message) {
        _error = message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
    return success;
  }

  Future<bool> updatePet(Pet pet) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _petRepository.updatePet(pet);
    final success = result.when(
      success: (_) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (message) {
        _error = message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
    return success;
  }

  Future<bool> deletePet(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _petRepository.deletePet(id);
    final success = result.when(
      success: (_) {
        _isLoading = false;
        notifyListeners();
        return true;
      },
      failure: (message) {
        _error = message;
        _isLoading = false;
        notifyListeners();
        return false;
      },
    );
    return success;
  }

  Future<Pet?> getPetById(String id) async {
    final result = await _petRepository.getPetById(id);
    return result.when(
      success: (pet) => pet,
      failure: (message) {
        _error = message;
        return null;
      },
    );
  }

  Stream<List<Pet>> getUserPetsStream(String userId) {
    final result = _petRepository.getUserPetsStream(userId);
    return result.when(
      success: (stream) => stream,
      failure: (message) {
        _error = message;
        return Stream.value([]);
      },
    );
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
