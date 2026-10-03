/// In-memory sample data used when Firebase is not reachable.
///
/// The app always tries the live connection first. Sample reports appear only
/// when the build has no Firebase credentials (a browser build without
/// `--dart-define-from-file`, a checkout without `google-services.json`) or
/// when Firebase cannot be reached at startup, so the interface never shows a
/// dead screen.
abstract final class DemoMode {
  /// Set to true (or build with `--dart-define=USE_SAMPLE_DATA=true`) to always
  /// use the offline sample reports, for example during a lecture without
  /// internet access.
  static const preferSampleData = false;

  /// True when the running app is serving the built-in sample reports.
  static bool enabled = preferSampleData;
}
