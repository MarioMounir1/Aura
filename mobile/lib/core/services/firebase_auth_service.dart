// lib/core/services/firebase_auth_service.dart
// Aura — Firebase Authentication Service
// Wraps FirebaseAuth + GoogleSignIn to provide a verified ID token.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  FirebaseAuthService._();
  static final FirebaseAuthService instance = FirebaseAuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '183282015983-a85d4fdna5esice6mrjgvasj5kk7pp1t.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // ── Current user ──────────────────────────────────────────────

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Google Sign-In ────────────────────────────────────────────

  /// Triggers the Google account picker, authenticates with Firebase,
  /// and returns a [GoogleSignInResult] with the user details and ID token
  /// to pass to the backend.
  Future<GoogleSignInResult?> signInWithGoogle() async {
    try {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Trigger the Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // user cancelled

      // Get authentication tokens
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create Firebase credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign into Firebase
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;
      if (user == null) return null;

      // Get a fresh Firebase ID token for the backend
      final String? firebaseIdToken = await user.getIdToken();

      return GoogleSignInResult(
        firebaseUid: user.uid,
        email: user.email ?? googleUser.email,
        name: user.displayName ?? googleUser.displayName ?? '',
        googleId: googleUser.id,
        idToken: firebaseIdToken,
        photoUrl: user.photoURL,
      );
    } catch (e, stackTrace) {
      String? runtimeSha1;
      try {
        const channel = MethodChannel('com.mario.aura/app_info');
        runtimeSha1 = await channel.invokeMethod<String>('getSigningSha1');
      } catch (_) {}

      final buffer = StringBuffer();
      buffer.writeln('Google Sign-In failed.');

      if (e is PlatformException) {
        buffer.writeln('Error Code: ${e.code}');
        if (e.message != null && e.message!.isNotEmpty) {
          buffer.writeln('Message: ${e.message}');
        }
        if (e.details != null) {
          buffer.writeln('Details: ${e.details}');
        }
        if (e.message?.contains(': 10') == true || e.code == '10') {
          buffer.writeln('💡 Hint: ApiException 10 (DEVELOPER_ERROR) indicates a SHA-1 fingerprint or package name mismatch in Firebase Console.');
        } else if (e.message?.contains(': 12500') == true || e.code == '12500') {
          buffer.writeln('💡 Hint: ApiException 12500 (SIGN_IN_FAILED) indicates Google Play Services configuration issue or missing SHA-1 in Firebase.');
        } else if (e.message?.contains(': 7') == true || e.code == '7') {
          buffer.writeln('💡 Hint: ApiException 7 (NETWORK_ERROR) indicates network error connecting to Google servers.');
        }
      } else if (e is FirebaseAuthException) {
        buffer.writeln('Firebase Auth Code: ${e.code}');
        buffer.writeln('Message: ${e.message ?? 'Unknown Firebase auth error'}');
        if (e.email != null) buffer.writeln('Email: ${e.email}');
      } else {
        buffer.writeln('Raw Error: $e');
      }

      if (runtimeSha1 != null && runtimeSha1.isNotEmpty) {
        buffer.writeln('\n📱 Installed App SHA-1:\n$runtimeSha1');
      }

      buffer.writeln('\nStack Trace:\n$stackTrace');

      throw Exception(buffer.toString());
    }
  }

  // ── Sign Out ──────────────────────────────────────────────────

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  // ── Refresh ID Token ──────────────────────────────────────────

  /// Returns a fresh Firebase ID token for the currently signed-in user,
  /// or null if not signed in.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    return await _auth.currentUser?.getIdToken(forceRefresh);
  }
}

// ── Result Model ─────────────────────────────────────────────────

class GoogleSignInResult {
  final String firebaseUid;
  final String email;
  final String name;
  final String googleId;
  final String? idToken;
  final String? photoUrl;

  const GoogleSignInResult({
    required this.firebaseUid,
    required this.email,
    required this.name,
    required this.googleId,
    this.idToken,
    this.photoUrl,
  });
}
