import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Google Analytics for Firebase. Never sends email, location, or report text.
class AnalyticsService {
  AnalyticsService._();
  static final AnalyticsService instance = AnalyticsService._();

  final _prefs = SharedPreferencesAsync();
  static const _enabledKey = 'risk_track_analytics_enabled';

  bool get _ready {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    try {
      return await _prefs.getBool(_enabledKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Applies the saved preference after [Firebase.initializeApp] succeeds.
  Future<void> applyPreference() async {
    await setEnabled(await isEnabled());
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await _prefs.setBool(_enabledKey, enabled);
    } catch (_) {}
    await _guard((analytics) => analytics.setAnalyticsCollectionEnabled(enabled));
  }

  Future<void> logScreen(String? name) => _guard((analytics) async {
        if (name == null || name.isEmpty) return;
        await analytics.logScreenView(screenName: name, screenClass: name);
      });

  Future<void> logLogin() =>
      _guard((analytics) => analytics.logLogin(loginMethod: 'email'));

  Future<void> logSignUp() =>
      _guard((analytics) => analytics.logSignUp(signUpMethod: 'email'));

  Future<void> logReportSubmitted(String category) => _guard(
        (analytics) => analytics.logEvent(
          name: 'report_submitted',
          parameters: {'category': category},
        ),
      );

  Future<void> _guard(
    Future<void> Function(FirebaseAnalytics analytics) action,
  ) async {
    if (!_ready) return;
    try {
      await action(FirebaseAnalytics.instance);
    } catch (_) {
      // Measurement must never block sign-in, reporting, or navigation.
    }
  }
}

/// Logs named routes only. Unnamed routes, including the splash home, are skipped.
class AnalyticsRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AnalyticsService.instance.logScreen(route.settings.name);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AnalyticsService.instance.logScreen(newRoute?.settings.name);
  }
}
