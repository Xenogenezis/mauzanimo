import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repositories/auth_repository.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;

  User? _user;
  UserProfile? _userProfile;
  String? _error;
  bool _isLoading = false;
  bool _isProfileLoading = false;

  AuthProvider(this._authRepository) {
    _user = _authRepository.currentUser;
    _authRepository.authStateChanges.listen((user) async {
      _user = user;
      if (user != null) {
        await _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // Getters
  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  bool get isProfileLoading => _isProfileLoading;
  String? get error => _error;
  String? get uid => _user?.uid;
  String? get email => _user?.email;
  String get displayName => _userProfile?.name ?? _user?.email ?? 'User';

  // Load user profile from Firestore
  Future<void> _loadUserProfile(String uid) async {
    _isProfileLoading = true;
    notifyListeners();

    try {
      _userProfile = await _authRepository.getUserProfile(uid);
    } catch (e) {
      // Profile not found is okay
    } finally {
      _isProfileLoading = false;
      notifyListeners();
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.signIn(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register with email and password
  Future<bool> register(String email, String password, String name, {String? phone}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.register(email, password, name, phone: phone);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authRepository.signOut();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.sendPasswordReset(email);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'An unexpected error occurred';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh user profile
  Future<void> refreshProfile() async {
    if (_user != null) {
      await _loadUserProfile(_user!.uid);
    }
  }
}
