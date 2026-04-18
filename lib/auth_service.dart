import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthUnavailableException implements Exception {
  const AuthUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthService {
  AuthService._();

  static bool _isReady = false;
  static Object? _initializationError;

  static bool get isReady => _isReady;
  static Object? get initializationError => _initializationError;

  static User? get currentUser {
    if (!_isReady) return null;
    return FirebaseAuth.instance.currentUser;
  }

  static Stream<User?> get authStateChanges {
    if (!_isReady) return Stream<User?>.value(null);
    return FirebaseAuth.instance.authStateChanges();
  }

  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();
      _isReady = true;
      _initializationError = null;
    } catch (error) {
      _isReady = false;
      _initializationError = error;
    }
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    _ensureReady();
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    _ensureReady();
    final credential =
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());
    return credential;
  }

  static Future<void> sendPasswordReset(String email) {
    _ensureReady();
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  static Future<void> signOut() async {
    if (!_isReady) return;
    await FirebaseAuth.instance.signOut();
  }

  static String userMessage(Object error) {
    if (error is AuthUnavailableException) return error.message;
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-email':
          return 'Enter a valid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Email or password is incorrect.';
        case 'email-already-in-use':
          return 'This email is already registered.';
        case 'weak-password':
          return 'Use a stronger password.';
        case 'too-many-requests':
          return 'Too many attempts. Try again later.';
        case 'network-request-failed':
          return 'Check your internet connection.';
      }
      return error.message ?? 'Authentication failed.';
    }
    return 'Authentication failed. Try again.';
  }

  static void _ensureReady() {
    if (_isReady) return;
    throw const AuthUnavailableException(
      'Firebase is not configured yet. Add GoogleService-Info.plist or run flutterfire configure.',
    );
  }
}
