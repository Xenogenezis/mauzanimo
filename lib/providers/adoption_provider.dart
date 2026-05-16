import 'package:flutter/material.dart';
import '../models/adoption.dart';
import '../repositories/adoption_repository.dart';
import '../utils/result.dart';

class AdoptionProvider extends ChangeNotifier {
  final AdoptionRepository _repository;
  final List<Adoption> _adoptions = [];
  bool _isLoading = false;
  String? _error;

  AdoptionProvider(this._repository);

  List<Adoption> get adoptions => _adoptions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> createAdoption(Adoption adoption) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await _repository.createAdoption(adoption);
    _isLoading = false;
    return result.when(
      success: (_) { notifyListeners(); return true; },
      failure: (msg) { _error = msg; notifyListeners(); return false; },
    );
  }

  Future<bool> updateStage(String id, AdoptionStage stage, {String? notes, String? changedBy}) async {
    final result = await _repository.updateStage(id, stage, notes: notes, changedBy: changedBy);
    return result.isSuccess;
  }

  Future<bool> rejectAdoption(String id, String reason) async {
    final result = await _repository.rejectAdoption(id, reason);
    return result.isSuccess;
  }

  void clearError() { _error = null; notifyListeners(); }
}
