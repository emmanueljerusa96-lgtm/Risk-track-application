import 'package:flutter/material.dart';

import '../utils/constants.dart';

class RiskLogo extends StatelessWidget {
  const RiskLogo({super.key, this.size = 76, this.showTagline = true});
  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.teal, AppColors.deepTeal],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * .29),
              boxShadow: [
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: .18),
                  blurRadius: 25, offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(Icons.place_rounded, color: Colors.white, size: size * .55),
          ),
          const SizedBox(height: 18),
          Text('Risk Track', style: TextStyle(
            fontSize: size > 60 ? 32 : 24, fontWeight: FontWeight.w800,
            letterSpacing: -.6, color: AppColors.ink,
          )),
          if (showTagline) ...[
            const SizedBox(height: 6),
            const Text(AppConstants.tagline,
              style: TextStyle(color: AppColors.muted, fontSize: 14)),
          ],
        ],
      );
}
