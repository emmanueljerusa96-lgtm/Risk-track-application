/// In-memory sample data so the app can be used before Firebase is connected.
abstract final class DemoMode {
  /// Flip to false when the live Firebase project should be used instead.
  static const preferSampleData = true;

  static bool enabled = preferSampleData;
}
