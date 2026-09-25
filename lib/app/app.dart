import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../services/analytics_service.dart';
import 'theme.dart';

class RiskTrackApp extends StatelessWidget {
  const RiskTrackApp({super.key});

  static final _analyticsObserver = AnalyticsRouteObserver();

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Risk Track',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        navigatorObservers: [_analyticsObserver],
        home: const SplashScreen(),
      );
}
