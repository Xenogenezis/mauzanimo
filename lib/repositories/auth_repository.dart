import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../utils/result.dart';

class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<Result<UserCredential>> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return Result.success(credential);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-disabled':
          message = 'This account has been disabled.';
          break;
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        case 'wrong-password':
          message = 'Incorrect password.';
          break;
        case 'invalid-credential':
          message = 'Invalid email or password.';
          break;
        case 'too-many-requests':
          message = 'Too many failed attempts. Please try again later.';
          break;
        default:
          message = e.message ?? 'Sign in failed. Please try again.';
      }
      return Result.failure(message, error: e);
    } catch (e, stackTrace) {
      return Result.failure(
        'Sign in failed. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Register with email and password
  Future<Result<UserCredential>> register(
    String email,
    String password,
    String name, {
    String? phone,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      // Create user profile in Firestore
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone?.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return Result.success(credential);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'An account already exists with this email.';
          break;
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'weak-password':
          message = 'Password is too weak. Please use at least 6 characters.';
          break;
        default:
          message = e.message ?? 'Registration failed. Please try again.';
      }
      return Result.failure(message, error: e);
    } catch (e, stackTrace) {
      return Result.failure(
        'Registration failed. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Sign out
  Future<Result<void>> signOut() async {
    try {
      await _auth.signOut();
      return Result.success(null);
    } catch (e, stackTrace) {
      return Result.failure(
        'Sign out failed. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Send password reset email
  Future<Result<void>> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return Result.success(null);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'invalid-email':
          message = 'Invalid email address.';
          break;
        case 'user-not-found':
          message = 'No account found with this email.';
          break;
        default:
          message = e.message ?? 'Failed to send reset email. Please try again.';
      }
      return Result.failure(message, error: e);
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to send reset email. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Get user profile
  Future<Result<UserProfile?>> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return Result.success(null);
      return Result.success(
        UserProfile.fromMap(doc.id, doc.data()!),
      );
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to load profile: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to load profile. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Update user profile
  Future<Result<void>> updateUserProfile(
    String uid,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
      return Result.success(null);
    } on FirebaseException catch (e, stackTrace) {
      return Result.failure(
        'Failed to update profile: ${e.message}',
        error: e,
        stackTrace: stackTrace,
      );
    } catch (e, stackTrace) {
      return Result.failure(
        'Failed to update profile. Please try again.',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;
}
