import 'package:flutter/material.dart';

/// Small navigation helper instead of a routing framework for a student app.
abstract final class AppRoutes {
  static String nameOf(Widget screen) => screen.runtimeType.toString();

  static Future<T?> push<T>(BuildContext context, Widget screen) =>
      Navigator.of(context).push<T>(
        MaterialPageRoute(
          settings: RouteSettings(name: nameOf(screen)),
          builder: (_) => screen,
        ),
      );

  static void replace(BuildContext context, Widget screen) {
    Navigator.of(context).pushReplacement<void, void>(
      MaterialPageRoute<void>(
        settings: RouteSettings(name: nameOf(screen)),
        builder: (_) => screen,
      ),
    );
  }
}
