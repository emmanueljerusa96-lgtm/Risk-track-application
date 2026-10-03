import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase project settings supplied at build time.
///
/// Nothing sensitive is committed. The values arrive as `--dart-define` flags,
/// which `--dart-define-from-file` also fills from a JSON file, so the very
/// same source works from VS Code, from the command line and from GitHub
/// Actions:
///
/// ```powershell
/// flutter run   -d chrome --dart-define-from-file=config/firebase-config.json
/// flutter build web --release --dart-define-from-file=config/firebase-config.json
/// ```
///
/// A Firebase web API key is a public client identifier, not a server secret,
/// but this project keeps it outside Git anyway. Android builds may keep using
/// `android/app/google-services.json` instead of these values.
abstract final class AppConfig {
  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const _storageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const _measurementId =
      String.fromEnvironment('FIREBASE_MEASUREMENT_ID');

  /// `--dart-define=USE_SAMPLE_DATA=true` forces the built-in sample reports,
  /// which is useful for an offline demonstration.
  static const useSampleData = bool.fromEnvironment('USE_SAMPLE_DATA');

  /// True when every value Firebase needs on all platforms was provided.
  static bool get hasFirebaseCredentials =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _projectId.isNotEmpty &&
      _messagingSenderId.isNotEmpty;

  static String get projectId => _projectId;

  /// Options for `Firebase.initializeApp`, or null when this build has none.
  static FirebaseOptions? get firebaseOptions {
    if (!hasFirebaseCredentials) return null;
    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain:
          _authDomain.isEmpty ? '$_projectId.firebaseapp.com' : _authDomain,
      storageBucket: _storageBucket.isEmpty
          ? '$_projectId.firebasestorage.app'
          : _storageBucket,
      measurementId: _measurementId.isEmpty ? null : _measurementId,
    );
  }

  /// Browsers cannot read `google-services.json`, so a web build only reaches
  /// Firebase when the `--dart-define` values above are present.
  static bool get needsBuildTimeCredentials => kIsWeb;
}
