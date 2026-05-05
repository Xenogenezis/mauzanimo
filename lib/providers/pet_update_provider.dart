import 'package:flutter/material.dart';
import '../models/pet_update.dart';
import '../repositories/pet_update_repository.dart';
import '../utils/result.dart';

class PetUpdateProvider extends ChangeNotifier {
  final PetUpdateRepository _repository;
  List<PetUpdate> _updates = [];
  bool _isLoading = false;
  String? _error;

  PetUpdateProvider(this._repository);

  List<PetUpdate> get updates => _updates;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> addUpdate(PetUpdate update) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await _repository.addUpdate(update);
    _isLoading = false;
    return result.when(
      success: (_) { notifyListeners(); return true; },
      failure: (msg) { _error = msg; notifyListeners(); return false; },
    );
  }

  void clearError() { _error = null; notifyListeners(); }
}
