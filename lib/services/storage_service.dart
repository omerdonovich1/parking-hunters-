import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  FirebaseStorage get _storage => FirebaseStorage.instance;

  /// Uploads a parking spot photo and returns the download URL.
  /// Returns null if Firebase Storage is not configured or upload fails.
  Future<String?> uploadSpotPhoto({
    required String userId,
    required String reportId,
    required String localFilePath,
  }) async {
    try {
      final file = File(localFilePath);
      if (!file.existsSync()) return null;

      final ext = localFilePath.split('.').last.toLowerCase();
      final ref = _storage
          .ref()
          .child('spot_photos')
          .child(userId)
          .child('$reportId.$ext');

      final metadata = SettableMetadata(
        contentType: 'image/$ext',
        customMetadata: {
          'reportId': reportId,
          'uploadedBy': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      final task = await ref.putFile(file, metadata);
      final downloadUrl = await task.ref.getDownloadURL();
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Storage upload error: ${e.code} — ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Storage upload error: $e');
      return null;
    }
  }

  /// Deletes a photo by its download URL (used when a report is removed).
  Future<void> deleteSpotPhoto(String downloadUrl) async {
    try {
      await _storage.refFromURL(downloadUrl).delete();
    } catch (e) {
      debugPrint('Storage delete error: $e');
    }
  }
}
