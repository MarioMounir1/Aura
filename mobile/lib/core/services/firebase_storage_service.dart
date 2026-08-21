// lib/core/services/firebase_storage_service.dart
// Aura — Firebase Storage Service
// Uploads meal photos and returns their public download URLs.

import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseStorageService {
  FirebaseStorageService._();
  static final FirebaseStorageService instance = FirebaseStorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  // ── Meal Photo Upload ─────────────────────────────────────────

  /// Uploads a meal photo for [userId] and returns its download URL.
  /// Stored at: meal_photos/{userId}/{timestamp}.jpg
  Future<String?> uploadMealPhoto({
    required String userId,
    required String localFilePath,
  }) async {
    try {
      final File file = File(localFilePath);
      if (!file.existsSync()) return null;

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage
          .ref()
          .child('meal_photos')
          .child(userId)
          .child('$timestamp.jpg');

      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      return null;
    }
  }

  // ── Profile Photo Upload ──────────────────────────────────────

  /// Uploads a profile avatar for [userId] and returns its download URL.
  /// Stored at: profile_photos/{userId}/avatar.jpg
  Future<String?> uploadProfilePhoto({
    required String userId,
    required String localFilePath,
  }) async {
    try {
      final File file = File(localFilePath);
      if (!file.existsSync()) return null;

      final Reference ref = _storage
          .ref()
          .child('profile_photos')
          .child(userId)
          .child('avatar.jpg');

      final UploadTask uploadTask = ref.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // ── Delete Photo ──────────────────────────────────────────────

  /// Deletes a file from Firebase Storage by its full download URL.
  Future<void> deleteByUrl(String downloadUrl) async {
    try {
      final Reference ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (_) {}
  }

  // ── Upload Progress Stream ────────────────────────────────────

  /// Uploads a meal photo and emits upload progress (0.0 – 1.0).
  Stream<double> uploadMealPhotoWithProgress({
    required String userId,
    required String localFilePath,
  }) async* {
    final File file = File(localFilePath);
    if (!file.existsSync()) return;

    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final Reference ref = _storage
        .ref()
        .child('meal_photos')
        .child(userId)
        .child('$timestamp.jpg');

    final UploadTask uploadTask = ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    await for (final TaskSnapshot snapshot in uploadTask.snapshotEvents) {
      if (snapshot.totalBytes > 0) {
        yield snapshot.bytesTransferred / snapshot.totalBytes;
      }
    }
  }
}
