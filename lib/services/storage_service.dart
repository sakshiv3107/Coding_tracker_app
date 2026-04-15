import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String? get currentUserId => _auth.currentUser?.uid;

  /// Picks an image from gallery or camera
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024, // Resize for efficiency
        maxHeight: 1024,
        imageQuality: 85, // Compress
      );

      if (pickedFile != null) {
        final File file = File(pickedFile.path);
        final int fileSize = await file.length();
        
        // Validate file size (< 5MB)
        if (fileSize > 5 * 1024 * 1024) {
          throw Exception("File size too large. Please select an image smaller than 5MB.");
        }
        
        return file;
      }
      return null;
    } catch (e) {
      debugPrint("Error picking image: $e");
      rethrow;
    }
  }

  /// Uploads profile picture to Firebase Storage and returns Download URL
  Future<String> uploadProfilePicture(File file) async {
    if (currentUserId == null) {
      throw Exception("User not authenticated");
    }

    try {
      final String fileName = 'profile_pics/$currentUserId.jpg';
      final Reference ref = _storage.ref().child(fileName);

      // Metada for storage
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': currentUserId!},
      );

      // Upload task
      final UploadTask uploadTask = ref.putFile(file, metadata);
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      if (e.toString().contains('storage/unauthorized')) {
        throw Exception("Upload failed: Permission denied. Please ensure your storage rules are configured.");
      }
      if (e.toString().contains('storage/quota-exceeded')) {
        throw Exception("Upload failed: Storage quota exceeded.");
      }
      throw Exception("Failed to upload image: $e");
    }
  }
}


