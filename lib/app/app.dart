import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import 'theme.dart';

class RiskTrackApp extends StatelessWidget {
  const RiskTrackApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Risk Track',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
      );
}
