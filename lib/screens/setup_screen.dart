import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../services/demo_mode.dart';
import '../services/mock_store.dart';
import '../utils/constants.dart';
import '../widgets/custom_button.dart';
import '../widgets/risk_logo.dart';
import 'splash_screen.dart';

/// No fabricated Firebase ID or API key: the build remains installable and
/// directs the owner to connect their own Firebase Android application.
class SetupScreen extends StatelessWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            const RiskLogo(size: 68),
            const SizedBox(height: 36),
            Text('Firebase is not connected',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 12),
            const Text(
              'Firebase is not connected, so the app can keep running on sample '
              'reports stored on this device. To use your own project later, add '
              'google-services.json and set DemoMode.preferSampleData to false.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const Spacer(),
            CustomButton(label: 'Continue with sample data', icon: Icons.explore_outlined,
              onPressed: () {
                DemoMode.enabled = true;
                MockStore.instance.signInSampleMember();
                AppRoutes.replace(context, const SplashScreen());
              }),
            const SizedBox(height: 10),
            TextButton(onPressed: () => AppRoutes.replace(context,
                const SplashScreen(tryFirebase: true)),
              child: const Text('Try Firebase again')),
          ]),
        )),
      );
}
