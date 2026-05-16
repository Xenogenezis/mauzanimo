import 'package:flutter/material.dart';
import '../models/review.dart';
import '../repositories/review_repository.dart';
import '../utils/result.dart';

class ReviewProvider extends ChangeNotifier {
  final ReviewRepository _repository;
  final List<Review> _reviews = [];
  bool _isLoading = false;
  String? _error;

  ReviewProvider(this._repository);

  List<Review> get reviews => _reviews;
  bool get isLoading => _isLoading;
  String? get error => _error;
  double get averageRating => _reviews.isEmpty ? 0.0 : _reviews.map((r) => r.rating).reduce((a, b) => a + b) / _reviews.length;

  Future<bool> addReview(Review review) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    final result = await _repository.addReview(review);
    _isLoading = false;
    return result.when(
      success: (_) { notifyListeners(); return true; },
      failure: (msg) { _error = msg; notifyListeners(); return false; },
    );
  }

  void clearError() { _error = null; notifyListeners(); }
}
