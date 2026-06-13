import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_games_services/firebase_auth_games_services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isPlayGamesUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return !user.isAnonymous;
  }

  Future<UserCredential?> signInAnonymously() async {
    try {
      return await _auth.signInAnonymously();
    } catch (e) {
      debugPrint('ERROR sign in anonymously: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithPlayGames({bool silent = false}) async {
    try {
      return await _auth.signInWithGamesServices(silent: silent);
    } catch (e) {
      debugPrint('ERROR sign in with Play Games Services (silent: $silent): $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('ERROR signing out: $e');
      rethrow;
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
