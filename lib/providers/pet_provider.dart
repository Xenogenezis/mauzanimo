import 'package:flutter/material.dart';
import '../repositories/pet_repository.dart';
import '../models/pet.dart';
import '../utils/result.dart';

class PetProvider extends ChangeNotifier {
  final PetRepository _petRepository;

  List<Pet> _pets = [];
  List<Pet> _filteredPets = [];
  String _searchQuery = '';
  String _selectedFilter = 'All';
  bool _isLoading = false;
  String? _error;

  PetProvider(this._petRepository) {
    // Listen to pets stream
    final result = _petRepository.getPetsStream();
    result.when(
      success: (stream) {
        stream.listen((pets) {
          _pets = pets;
          _applyFilters();
        });
      },
      failure: (message) {
        _error = message;
        notifyListeners();
      },
    );
  }

  // Getters
  List<Pet> get pets => _filteredPets;
  String get searchQuery => _searchQuery;
  String get selectedFilter => _selectedFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Available filters
  List<String> get filters => ['All', 'Dogs', 'Cats', 'Others'];

  // Get pets stream for UI
  Stream<List<Pet>> get petsStream {
    final result = _petRepository.getPetsStream(typeFilter: _selectedFilter);
    return result.when(
      success: (stream) => stream,
      failure: (message) {
        _error = message;
        return Stream.value([]);
      },
    );
  }

  // Apply search and filter
  void _applyFilters() {
    var result = _pets;

    // Apply type filter
    if (_selectedFilter != 'All') {
      result = result.where((pet) {
        if (_selectedFilter == 'Dogs') return pet.type.toLowerCase() == 'dogs';
        if (_selectedFilter == 'Cats') return pet.type.toLowerCase() == 'cats';
        return pet.type.toLowerCase() != 'dogs' && pet.type.toLowerCase() != 'cats';
      }).toList();
    }

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((pet) {
        return pet.name.toLowerCase().contains(query) ||
            pet.location.toLowerCase().contains(query);
      }).toList();
    }

    _filteredPets = result;
    notifyListeners();
  }

  // Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  // Set type filter
  void setFilter(String filter) {
    _selectedFilter = filter;
    _applyFilters();
  }

  // Add a new pet
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

  // Update a pet
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

  // Delete a pet
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

  // Get pet by ID
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

  // Get user pets stream
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

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
