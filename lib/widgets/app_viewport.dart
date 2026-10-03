import 'package:flutter/material.dart';

import '../utils/constants.dart';

/// Keeps the mobile-first interface comfortable on a desktop browser.
///
/// Phone-sized windows render exactly as before. On a wide screen the app is
/// centred in a phone-width column over the brand canvas colour, so the layout
/// is not stretched across a 27-inch monitor.
class AppViewport extends StatelessWidget {
  const AppViewport({super.key, required this.child});

  final Widget child;

  static const maxWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width <= maxWidth + 32) return child;
    return ColoredBox(
      color: AppColors.canvas,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: maxWidth),
          child: DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Color(0x1A17323B), blurRadius: 32,
                  offset: Offset(0, 10)),
              ],
            ),
            child: ClipRect(child: child),
          ),
        ),
      ),
    );
  }
}
