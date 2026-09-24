import 'package:flutter/material.dart';

import '../models/risk_report_model.dart';
import '../utils/constants.dart';

class RiskMarker extends StatelessWidget {
  const RiskMarker({super.key, required this.report, required this.onTap,
    this.highlighted = false});
  final RiskReportModel report;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: '${report.category.label}: ${report.title}. '
            '${report.verificationStatus.label}',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: highlighted ? 49 : 43,
            height: highlighted ? 49 : 43,
            decoration: BoxDecoration(
              color: report.verificationStatus == VerificationStatus.verified
                  ? AppColors.teal : report.category.color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x44000000),
                blurRadius: 9, offset: Offset(0, 3))],
            ),
            child: Icon(report.category.icon, color: Colors.white, size: 23),
          ),
        ),
      );
}
