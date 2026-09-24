import 'package:flutter/material.dart';

import '../utils/constants.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: TextStyle(
          color: color, fontSize: 11, fontWeight: FontWeight.w700,
        )),
      );
}

class DisclaimerCard extends StatelessWidget {
  const DisclaimerCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.mint, borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline, color: AppColors.deepTeal, size: 21),
          SizedBox(width: 10),
          Expanded(child: Text(AppConstants.disclaimer,
            style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.ink))),
        ]),
      );
}
