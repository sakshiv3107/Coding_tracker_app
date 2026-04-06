import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  // Google Sign-In instance.
  // Note: serverClientId is NOT set here because on Android it causes
  // ApiException: 10 when the SHA-1 fingerprint is not yet registered.
  // The web client ID is picked up automatically from google-services.json.
  // If you need an idToken for a custom backend, re-add serverClientId after
  // registering your SHA-1 in the Firebase Console.
  final gsi.GoogleSignIn _googleSignIn = gsi.GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final ProfileService _profileService = ProfileService();
  final _secureStorage = const FlutterSecureStorage();

  // Persist authentication state
  Future<void> _persistAuthData(String uid, String email, String name) async {
    await _secureStorage.write(key: 'auth_uid', value: uid);
    await _secureStorage.write(key: 'auth_email', value: email);
    await _secureStorage.write(key: 'auth_name', value: name);
    // You can also persist an auth token here if using a custom backend
  }

  Future<void> clearAuthData() async {
    await _secureStorage.delete(key: 'auth_uid');
    await _secureStorage.delete(key: 'auth_email');
    await _secureStorage.delete(key: 'auth_name');
  }

  // Get persisted auth data on app launch
  Future<Map<String, String>?> getPersistedUser() async {
    final uid = await _secureStorage.read(key: 'auth_uid');
    if (uid != null && uid.isNotEmpty) {
      final email = await _secureStorage.read(key: 'auth_email') ?? '';
      final name = await _secureStorage.read(key: 'auth_name') ?? 'User';
      return {
        "uid": uid,
        "email": email,
        "name": name,
      };
    }
    return null;
  }

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
      
      // Persist auth locally
      await _persistAuthData(userCredential.user!.uid, email, name);

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

      final String name = userCredential.user!.displayName ?? email.split('@')[0];

      // Persist auth locally
      await _persistAuthData(userCredential.user!.uid, email, name);

      return {
        "uid": userCredential.user!.uid,
        "email": userCredential.user!.email ?? "",
        "name": name,
        "isNewUser": false,
      };
    } on FirebaseAuthException catch (e) {
      // In newer Firebase versions, fetchSignInMethodsForEmail is removed for security.
      // We rely on standard error codes.
      if (e.code == 'invalid-credential' ||
          e.code == 'wrong-password' ||
          e.code == 'user-not-found') {
        throw Exception("Invalid email or password. Please try again.");
      }
      throw Exception(_handleFirebaseException(e));
    }
  }



  // Google Sign In — returns isNewUser flag
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final gsi.GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw Exception("Google sign in cancelled");
      }

      final gsi.GoogleSignInAuthentication googleAuth =
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

      // Persist auth locally
      await _persistAuthData(
        userCredential.user!.uid, 
        userCredential.user!.email ?? "", 
        userCredential.user!.displayName ?? "User",
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
      final msg = e.toString();
      if (msg.contains('cancelled') || msg.contains('canceled')) {
        throw Exception('Google sign in cancelled');
      }
      throw Exception('Google sign in failed: $msg');
    }
  }



  // Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();

      // Sign out Google silently to force account-picker next time
      try {
        await _googleSignIn.signOut();
      } catch (_) {} // Non-fatal: user may have signed in with email

      // ── Full SharedPreferences cleanup ───────────────────────────────
      // Wiping all preferences completely as requested to ensure no stale data remains
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // ── Clear secure storage auth tokens ─────────────────────────────────
      await clearAuthData();

      // NOTE: We intentionally do NOT call Hive.deleteFromDisk() here.
      // Hive stores goal data which should NOT be wiped on logout.
      // If you need to wipe Hive data on logout you should do it per-box:
      //   await Hive.box('goals').clear();

    } catch (e) {
      throw Exception("Logout failed: ${e.toString()}");
    }
  }

  // Password reset
  Future<void> resetPassword(String email) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty) {
      throw Exception("Email is required");
    }

    // Validate basic email format
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(trimmedEmail)) {
      throw Exception("Please enter a valid email address");
    }

    try {
      await _firebaseAuth.sendPasswordResetEmail(email: trimmedEmail);
    } on FirebaseAuthException catch (e) {
      // Firebase v9+ may return 'user-not-found' for unregistered emails
      if (e.code == 'user-not-found') {
        throw Exception("No account found with this email. Please sign up first.");
      }
      if (e.code == 'invalid-email') {
        throw Exception("The email address is not valid.");
      }
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
