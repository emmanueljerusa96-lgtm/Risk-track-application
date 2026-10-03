import 'package:flutter/material.dart';

import '../screens/splash_screen.dart';
import '../services/analytics_service.dart';
import '../widgets/app_viewport.dart';
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
        builder: (context, child) =>
            AppViewport(child: child ?? const SizedBox.shrink()),
        home: const SplashScreen(),
      );
}
