import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Save user basic info to Firestore
  Future<void> saveUserInfo({
    required String email,
    required String name,
  }) async {
    if (currentUserId == null) {
      throw Exception("User not authenticated");
    }

    try {
      await _db.collection('users').doc(currentUserId).set({
        'uid': currentUserId,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception("Failed to save user info: ${e.toString()}");
    }
  }

  // Save user coding profile
  Future<void> saveCodingProfile({
    required String leetcode,
    required String codechef,
    required String codeforces,
    required String github,
  }) async {
    if (currentUserId == null) {
      throw Exception("User not authenticated");
    }

    try {
      await _db.collection('users').doc(currentUserId).set({
        'profile': {
          'leetcode': leetcode,
          'codechef': codechef,
          'codeforces': codeforces,
          'github': github,
        },
        'profileCompleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception("Failed to save coding profile: ${e.toString()}");
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUserId == null) {
      return null;
    }

    try {
      final doc = await _db.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get user profile: ${e.toString()}");
    }
  }

  // Get coding profile
  Future<Map<String, String>?> getCodingProfile() async {
    if (currentUserId == null) {
      return null;
    }

    try {
      final doc = await _db.collection('users').doc(currentUserId).get();
      if (doc.exists && doc.data()?['profile'] != null) {
        final profileData = doc.data()?['profile'];
        return {
          'leetcode': profileData['leetcode'] ?? '',
          'codechef': profileData['codechef'] ?? '',
          'codeforces': profileData['codeforces'] ?? '',
          'github': profileData['github'] ?? '',
        };
      }
      return null;
    } catch (e) {
      throw Exception("Failed to get coding profile: ${e.toString()}");
    }
  }

  // Check if profile is completed
  Future<bool> isProfileCompleted() async {
    if (currentUserId == null) {
      return false;
    }

    try {
      final doc = await _db.collection('users').doc(currentUserId).get();
      if (doc.exists) {
        return doc.data()?['profileCompleted'] ?? false;
      }
      return false;
    } catch (e) {
      throw Exception("Failed to check profile completion: ${e.toString()}");
    }
  }

  // Delete user profile
  Future<void> deleteUserProfile() async {
    if (currentUserId == null) {
      throw Exception("User not authenticated");
    }

    try {
      await _db.collection('users').doc(currentUserId).delete();
    } catch (e) {
      throw Exception("Failed to delete user profile: ${e.toString()}");
    }
  }

  // Stream for real-time profile updates
  Stream<DocumentSnapshot<Map<String, dynamic>>>? getUserProfileStream() {
    if (currentUserId == null) {
      return null;
    }

    return _db.collection('users').doc(currentUserId).snapshots();
  }
}
