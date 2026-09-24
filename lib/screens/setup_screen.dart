import 'package:flutter/material.dart';

import '../app/routes.dart';
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
            Text('Connect Firebase to continue',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.ink)),
            const SizedBox(height: 12),
            const Text(
              'This build has no Firebase configuration yet. The project owner '
              'needs to register this Android app in Firebase and place '
              'google-services.json in android/app/, then rebuild the app. '
              'See README.md for the exact steps.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, height: 1.5),
            ),
            const Spacer(),
            CustomButton(label: 'Try again', icon: Icons.refresh,
              onPressed: () => AppRoutes.replace(context, const SplashScreen())),
          ]),
        )),
      );
}
