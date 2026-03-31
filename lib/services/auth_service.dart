import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  
  // Google Sign-In instance.
  // Note: serverClientId is NOT set here because on Android it causes
  // ApiException: 10 when the SHA-1 fingerprint is not yet registered.
  // The web client ID is picked up automatically from google-services.json.
  // If you need an idToken for a custom backend, re-add serverClientId after
  // registering your SHA-1 in the Firebase Console.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
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
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_failed') {
        final msg = e.message ?? '';
        if (msg.contains('ApiException: 10')) {
          throw Exception(
            'Google Sign-In configuration error (code 10).\n'
            'To fix this:\n'
            '1. Go to Firebase Console → Project Settings → Your Android App\n'
            '2. Add debug SHA-1: 62:A6:D5:38:77:E3:29:2E:A9:9E:31:9B:4B:72:FC:21:F8:1B:72:20\n'
            '3. Download the updated google-services.json\n'
            '4. Enable Google Sign-In in Firebase Console → Authentication → Sign-in method',
          );
        }
        if (msg.contains('ApiException: 12501')) {
          // User cancelled — not an error
          throw Exception('Google sign in cancelled');
        }
      }
      throw Exception('Google Sign-In failed: ${e.message ?? e.toString()}');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('cancelled') || msg.contains('canceled')) {
        throw Exception('Google sign in cancelled');
      }
      throw Exception('Google sign in failed: $msg');
    }
  }

  // ─── Keys we intentionally clear on logout ────────────────────────────────
  // We do NOT call prefs.clear() because that would wipe:
  //   • profile_completed flag  → causes ProfileSetup to show again on next login
  //   • disk-cached stats       → triggers unnecessary API calls on next login
  //   • disk-cached goals       → goal data is lost
  //
  // We only delete the user-session auth tokens and the profile-completed flag
  // so that the next login re-fetches the profile from Firestore (correct behavior).
  static const List<String> _kPrefsToDeleteOnLogout = [
    'profile_completed', // ProfileProvider flag — must be cleared so next login refetches
  ];

  // Logout
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();

      // Sign out Google silently to force account-picker next time
      try {
        await _googleSignIn.signOut();
      } catch (_) {} // Non-fatal: user may have signed in with email

      // ── Selective SharedPreferences cleanup ───────────────────────────────
      // Only delete auth-session keys. Stats cache & goals stay on disk so the
      // next user session can reuse them (they are user-scoped via Firestore).
      final prefs = await SharedPreferences.getInstance();
      for (final key in _kPrefsToDeleteOnLogout) {
        await prefs.remove(key);
      }

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
