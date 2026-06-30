import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import 'firebase_service.dart';

class DefectStorageService {
  DefectStorageService(this._storage);

  final FirebaseStorage _storage;

  Future<String?> uploadDefectImage({
    required XFile? image,
    required String userId,
  }) async {
    if (image == null) return null;
    if (!FirebaseService.isInitialized) {
      throw const StorageFailure(
        'Firebase is not configured yet. Complete the setup steps in README.md.',
      );
    }

    final extension = image.name.split('.').last.toLowerCase();
    final safeExtension = extension.isEmpty || extension.length > 5
        ? 'jpg'
        : extension;
    final contentType = safeExtension == 'jpg'
        ? 'image/jpeg'
        : 'image/$safeExtension';
    final objectName =
        '${DateTime.now().millisecondsSinceEpoch}.$safeExtension';
    final ref = _storage.ref('defect-images/$userId/$objectName');

    final uploadTask = await ref.putFile(
      File(image.path),
      SettableMetadata(contentType: contentType),
    );

    return uploadTask.ref.getDownloadURL();
  }
}

class StorageFailure implements Exception {
  const StorageFailure(this.message);
  final String message;
}

final defectStorageServiceProvider = Provider<DefectStorageService>((ref) {
  return DefectStorageService(FirebaseStorage.instance);
});
