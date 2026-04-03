import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static FirebaseAuth? get _auth {
    try { return FirebaseAuth.instance; } catch (_) { return null; }
  }

  // On web without a clientId, GoogleSignIn will throw — catch it at call site.
  GoogleSignIn? _googleSignIn;
  GoogleSignIn _getGoogleSignIn() {
    _googleSignIn ??= GoogleSignIn();
    return _googleSignIn!;
  }

  User? get currentUser => _auth?.currentUser;

  Stream<User?> get authStateChanges {
    try { return FirebaseAuth.instance.authStateChanges(); }
    catch (_) { return Stream.value(null); }
  }

  Future<User?> signInWithGoogle() async {
    try {
      final googleUser = await _getGoogleSignIn().signIn();
      if (googleUser == null) return null;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final uc = await _auth!.signInWithCredential(credential);
      return uc.user;
    } catch (e) {
      debugPrint('Google sign in error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithApple() async {
    try {
      final apple = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: apple.identityToken,
        accessToken: apple.authorizationCode,
      );
      final uc = await _auth!.signInWithCredential(oauthCredential);
      return uc.user;
    } catch (e) {
      debugPrint('Apple sign in error: $e');
      rethrow;
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final uc = await _auth!.signInWithEmailAndPassword(email: email.trim(), password: password);
      return uc.user;
    } catch (e) {
      debugPrint('Email sign in error: $e');
      rethrow;
    }
  }

  Future<User?> signUp(String email, String password, String displayName) async {
    try {
      final uc = await _auth!.createUserWithEmailAndPassword(email: email.trim(), password: password);
      await uc.user?.updateDisplayName(displayName);
      return uc.user;
    } catch (e) {
      debugPrint('Sign up error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        if (_auth != null) _auth!.signOut(),
        _googleSignIn?.signOut() ?? Future.value(),
      ]);
    } catch (e) {
      debugPrint('Sign out error: $e');
    }
  }
}
