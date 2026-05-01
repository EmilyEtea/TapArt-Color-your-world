import 'package:firebase_auth/firebase_auth.dart';

// handles lahat ng Firebase Auth stuff — login, register, logout
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Currently signed-in user (null if not signed in).
  User? get currentUser => _auth.currentUser;

  /// Display name ng current user — yung name na ni-input sa registration.
  /// Kung wala (baka lumang account), fallback sa email prefix.
  String get displayName {
    final user = _auth.currentUser;
    if (user == null) return '';
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    return user.email?.split('@').first ?? 'Artist';
  }

  /// Register with email + password, then set the display name.
  Future<UserCredential> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await cred.user?.updateDisplayName(name.trim());
    return cred;
  }

  /// Sign in with email + password.
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Sign out.
  Future<void> signOut() => _auth.signOut();

  /// Human-readable error message from a [FirebaseAuthException].
  static String friendlyError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email is already registered. Try signing in! 😊';
      case 'invalid-email':
        return 'That email address doesn\'t look right. 🤔';
      case 'weak-password':
        return 'Password must be at least 6 characters. 🔒';
      case 'user-not-found':
        return 'No account found for that email. 🕵️';
      case 'wrong-password':
        return 'Wrong password. Give it another try! 🔑';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment. ⏳';
      case 'network-request-failed':
        return 'Network error. Check your connection. 📶';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }
}
