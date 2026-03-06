import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'profile_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final ProfileService _profileService = ProfileService();

  // Get current user
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  Map<String, String>? get currentUser {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      return {
        "uid": user.uid,
        "email": user.email ?? "",
        "name": user.displayName ?? user.email?.split('@')[0] ?? "User",
      };
    }
    return null;
  }

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Sign up with email and password
  Future<Map<String, String>> signUp(
    String email,
    String password,
    String name,
  ) async {
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      throw Exception("All fields required");
    }

    if (password.length < 6) {
      throw Exception("Password must be at least 6 characters");
    }

    try {
      final UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      // Update display name
      await userCredential.user?.updateDisplayName(name);
      await userCredential.user?.reload();

      // Save user info to Firestore
      await _profileService.saveUserInfo(email: email, name: name);

      return {
        "uid": userCredential.user!.uid,
        "email": userCredential.user!.email ?? "",
        "name": name,
      };
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Login with email and password
  Future<Map<String, String>> login(String email, String password) async {
    if (email.isEmpty || password.isEmpty) {
      throw Exception("All fields required");
    }

    try {
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      return {
        "uid": userCredential.user!.uid,
        "email": userCredential.user!.email ?? "",
        "name": userCredential.user!.displayName ?? email.split('@')[0],
      };
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Google Sign In
  Future<Map<String, String>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception("Google sign in cancelled");
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);

      // Save user info to Firestore
      await _profileService.saveUserInfo(
        email: userCredential.user!.email ?? "",
        name: userCredential.user!.displayName ?? "User",
      );

      return {
        "uid": userCredential.user!.uid,
        "email": userCredential.user!.email ?? "",
        "name": userCredential.user!.displayName ?? "User",
      };
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    } catch (e) {
      throw Exception("Google sign in failed: ${e.toString()}");
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw Exception("Logout failed: ${e.toString()}");
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    if (email.isEmpty) {
      throw Exception("Email is required");
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleFirebaseException(e);
    }
  }

  // Handle Firebase exceptions
  String _handleFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
