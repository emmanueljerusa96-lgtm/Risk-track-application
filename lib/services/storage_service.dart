import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'demo_mode.dart';

class UploadedReportPhoto {
  const UploadedReportPhoto({required this.path, required this.url});
  final String path;
  final String url;
}

class StorageService {
  StorageService({FirebaseStorage? storage}) : _storage = storage;
  final FirebaseStorage? _storage;

  bool get _demo => DemoMode.enabled && _storage == null;
  FirebaseStorage get _firebaseStorage => _storage ?? FirebaseStorage.instance;

  Future<UploadedReportPhoto> uploadReportImage({
    required String uid,
    required String reportId,
    required XFile image,
  }) async {
    final size = await image.length();
    if (size > AppConstants.maxImageBytes) {
      throw const PhotoFailure('Photo must be smaller than 5 MB.');
    }
    final lower = image.name.toLowerCase();
    final isPng = lower.endsWith('.png');
    if (!isPng && !lower.endsWith('.jpg') && !lower.endsWith('.jpeg')) {
      throw const PhotoFailure('Choose a JPG or PNG photo.');
    }
    final extension = isPng ? 'png' : 'jpg';
    final mime = isPng ? 'image/png' : 'image/jpeg';
    if (_demo) {
      return UploadedReportPhoto(path: image.path, url: image.path);
    }
    final path = 'risk_reports/$uid/$reportId/photo.$extension';
    final ref = _firebaseStorage.ref(path);
    await ref.putFile(File(image.path), SettableMetadata(contentType: mime));
    try {
      return UploadedReportPhoto(path: path, url: await ref.getDownloadURL());
    } catch (_) {
      await deleteOrphanedPhoto(path);
      rethrow;
    }
  }

  Future<void> deleteOrphanedPhoto(String path) async {
    try {
      if (_demo) return;
      await _firebaseStorage.ref(path).delete();
    } catch (_) {
      // A failed cleanup must not mask the original report submission error.
    }
  }
}
