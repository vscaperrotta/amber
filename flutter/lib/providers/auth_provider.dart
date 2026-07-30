import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../utils/i18n.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  bool _isLoading = false;
  String? _error;

  AuthProvider() {
    _user = _authService.currentUser;
    _authService.authStateChanges.listen((user) {
      _user = user;
      notifyListeners();
    });
  }

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get displayName => _user?.email?.split('@').first;

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signUp(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      // ponytail: covers core/no-app etc. — a misconfigured build must not
      // masquerade as a generic "try again" error.
      _error = _mapFirebaseError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] unexpected auth error: $e');
      _error = t('auth.errorUnexpected');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.signIn(email: email, password: password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } on FirebaseException catch (e) {
      // ponytail: covers core/no-app etc. — a misconfigured build must not
      // masquerade as a generic "try again" error.
      _error = _mapFirebaseError(e.code);
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] unexpected auth error: $e');
      _error = t('auth.errorUnexpected');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return t('auth.errorEmailInUse');
      case 'invalid-email':
        return t('auth.errorInvalidEmail');
      case 'weak-password':
        return t('auth.errorWeakPassword');
      case 'user-not-found':
        return t('auth.errorUserNotFound');
      case 'wrong-password':
        return t('auth.errorWrongPassword');
      case 'invalid-credential':
        return t('auth.errorInvalidCredential');
      default:
        return t('auth.errorGeneric', {'code': code});
    }
  }
}
