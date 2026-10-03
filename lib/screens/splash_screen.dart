import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/routes.dart';
import '../services/analytics_service.dart';
import '../services/app_config.dart';
import '../services/demo_mode.dart';
import '../services/mock_store.dart';
import '../utils/constants.dart';
import '../widgets/risk_logo.dart';
import 'auth_gate.dart';
import 'onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.tryFirebase = false});
  final bool tryFirebase;
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Connects to the live Firebase project when this build carries credentials
  /// (or when a phone is running with `google-services.json`), and otherwise
  /// keeps the interface usable with the built-in sample reports.
  Future<void> _prepareBackend() async {
    final wantsSampleData = AppConfig.useSampleData ||
        (DemoMode.preferSampleData && !widget.tryFirebase);
    if (wantsSampleData) {
      _useSampleData();
      return;
    }

    final options = AppConfig.firebaseOptions;
    if (options == null && AppConfig.needsBuildTimeCredentials) {
      // A browser build has no google-services.json to fall back on, so it can
      // only reach Firebase through --dart-define values.
      _useSampleData();
      return;
    }

    try {
      // On Android/iOS a null `options` uses the native configuration file.
      await Firebase.initializeApp(options: options);
      DemoMode.enabled = false;
      try {
        await AnalyticsService.instance.applyPreference();
      } catch (_) {
        // Measurement must not block the rest of startup.
      }
    } catch (_) {
      _useSampleData();
    }
  }

  void _useSampleData() {
    DemoMode.enabled = true;
    MockStore.instance.signInSampleMember();
  }

  Future<void> _start() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    await _prepareBackend();
    bool seen = false;
    try {
      seen =
          await SharedPreferencesAsync().getBool('onboarding_complete') ?? false;
    } catch (_) {
      // Onboarding is safe to display if local preferences are unavailable.
    }
    if (!mounted) return;
    AppRoutes.replace(context,
        seen ? const AuthGate() : const OnboardingScreen());
  }

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: SafeArea(child: Column(children: [
          Spacer(),
          Center(child: RiskLogo(size: 90)),
          Spacer(),
          Padding(
            padding: EdgeInsets.only(bottom: 28),
            child: Column(children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 12),
              Text('Made for a more informed community',
                style: TextStyle(color: AppColors.muted, fontSize: 12)),
            ]),
          ),
        ])),
      );
}
