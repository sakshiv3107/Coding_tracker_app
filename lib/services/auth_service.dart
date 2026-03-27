import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
  Future<Map<String, dynamic>> signUp(
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
        "isNewUser": true,
      };
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseException(e));
    }
  }

  // Login with email and password
  // Firebase SDK v9+ returns 'invalid-credential' for BOTH wrong-password and user-not-found.
  // To distinguish: first fetch sign-in methods for the email.
  Future<Map<String, dynamic>> login(String email, String password) async {
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
        "isNewUser": false,
      };
    } on FirebaseAuthException catch (e) {
      // For 'invalid-credential' we disambiguate via fetchSignInMethodsForEmail
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        final methods = await _tryFetchSignInMethods(email);
        if (methods == null || methods.isEmpty) {
          throw Exception("User not registered. Sign up now.");
        } else {
          throw Exception("Incorrect password. Please try again.");
        }
      }
      throw Exception(_handleFirebaseException(e));
    }
  }

  /// Safely fetch sign-in methods; returns null on error (network etc.)
  Future<List<String>?> _tryFetchSignInMethods(String email) async {
    try {
      return await _firebaseAuth.fetchSignInMethodsForEmail(email);
    } catch (_) {
      return null;
    }
  }

  // Google Sign In — returns isNewUser flag
  Future<Map<String, dynamic>> signInWithGoogle() async {
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

      final UserCredential userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      final bool isNew =
          userCredential.additionalUserInfo?.isNewUser ?? false;

      // Save user info to Firestore for ALL users (merge, so old data is safe)
      await _profileService.saveUserInfo(
        email: userCredential.user!.email ?? "",
        name: userCredential.user!.displayName ?? "User",
      );

      return {
        "uid": userCredential.user!.uid,
        "email": userCredential.user!.email ?? "",
        "name": userCredential.user!.displayName ?? "User",
        "isNewUser": isNew,
      };
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleFirebaseException(e));
    } catch (e) {
      throw Exception("Google sign in failed: ${e.toString()}");
    }
  }

  // Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      
      // Clear Firestore offline cache (optional, but good for clean start)
      // await FirebaseFirestore.instance.terminate();
      // await FirebaseFirestore.instance.clearPersistence();

      // Clear local SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear Hive boxes
      await Hive.deleteFromDisk();
      
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
      throw Exception(_handleFirebaseException(e));
    }
  }

  // Handle Firebase exceptions
  String _handleFirebaseException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak (min 6 characters).';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'User not registered. Sign up now.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid credentials. Please check and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return 'An authentication error occurred: ${e.message}';
    }
  }
}
