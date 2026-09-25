import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app/routes.dart';
import '../services/analytics_service.dart';
import '../utils/constants.dart';
import '../widgets/risk_logo.dart';
import 'auth_gate.dart';
import 'onboarding_screen.dart';
import 'setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
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
    try {
      await Firebase.initializeApp();
    } catch (_) {
      if (mounted) AppRoutes.replace(context, const SetupScreen());
      return;
    }
    try {
      await AnalyticsService.instance.applyPreference();
    } catch (_) {
      // Measurement must not block the rest of startup.
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
