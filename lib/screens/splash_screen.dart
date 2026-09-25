import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/routes.dart';
import '../services/analytics_service.dart';
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

  Future<void> _start() async {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final tryLive = widget.tryFirebase || !DemoMode.preferSampleData;
    if (!tryLive) {
      DemoMode.enabled = true;
    } else {
      try {
        await Firebase.initializeApp();
        DemoMode.enabled = false;
      } catch (_) {
        DemoMode.enabled = true;
      }
      if (!DemoMode.enabled) {
        try {
          await AnalyticsService.instance.applyPreference();
        } catch (_) {
          // Measurement must not block the rest of startup.
        }
      }
    }
    if (DemoMode.enabled) {
      MockStore.instance.signInSampleMember();
    }
    bool seen = false;
    try {
      seen = await SharedPreferencesAsync().getBool('onboarding_complete') ?? false;
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
