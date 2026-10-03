import 'dart:convert';
import 'dart:typed_data';

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

/// Uploads report photos to Firebase Storage.
///
/// `putData` is used instead of `putFile` because it is the one upload call
/// that behaves identically on a phone, in a browser and in sample-data mode.
/// The `dart:io` `File` class, which does not exist on the web, is not needed.
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
    final bytes = await image.readAsBytes();
    if (bytes.length > AppConstants.maxImageBytes) {
      throw const PhotoFailure('Photo must be smaller than 5 MB.');
    }
    final kind = _imageKind(bytes);
    if (kind == _PhotoKind.other) {
      throw const PhotoFailure('Choose a JPG or PNG photo.');
    }
    final extension = kind == _PhotoKind.png ? 'png' : 'jpg';
    final mime = kind == _PhotoKind.png ? 'image/png' : 'image/jpeg';

    if (_demo) {
      // Sample data stays in memory. A data URL renders on every platform, so
      // a photo picked in the browser preview behaves like an uploaded one.
      return UploadedReportPhoto(
        path: 'sample/$reportId/photo.$extension',
        url: 'data:$mime;base64,${base64Encode(bytes)}',
      );
    }

    final path = 'risk_reports/$uid/$reportId/photo.$extension';
    final ref = _firebaseStorage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(
        contentType: mime,
        cacheControl: 'public, max-age=31536000',
      ),
    );
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

  /// Judges a pick by its file signature. Browsers do not always pass a usable
  /// file name, so the bytes are the reliable source of truth.
  _PhotoKind _imageKind(Uint8List bytes) {
    if (bytes.length > 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return _PhotoKind.png;
    }
    if (bytes.length > 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return _PhotoKind.jpeg;
    }
    return _PhotoKind.other;
  }
}

enum _PhotoKind { png, jpeg, other }
