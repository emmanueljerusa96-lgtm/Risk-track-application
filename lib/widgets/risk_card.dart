import 'package:flutter/material.dart';

import '../models/risk_report_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import 'status_badge.dart';

class RiskCard extends StatelessWidget {
  const RiskCard({super.key, required this.report, required this.onTap,
    this.distanceKm, this.showStatus = false});
  final RiskReportModel report;
  final VoidCallback onTap;
  final double? distanceKm;
  final bool showStatus;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: report.category.color.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(report.category.icon, color: report.category.color),
                ),
                const SizedBox(width: 11),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700,
                        color: AppColors.ink, fontSize: 15)),
                    const SizedBox(height: 3),
                    Text('${report.category.label} · ${AppHelpers.timeAgo(report.createdAt)}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12)),
                  ],
                )),
                const Icon(Icons.chevron_right, color: AppColors.muted),
              ]),
              const SizedBox(height: 11),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 16,
                    color: AppColors.muted),
                const SizedBox(width: 3),
                Expanded(child: Text(report.address,
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 12))),
                if (distanceKm != null) Text(' · ${distanceKm!.toStringAsFixed(1)} km',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 7, runSpacing: 6, children: [
                StatusBadge(label: report.verificationStatus.label,
                    color: report.verificationStatus.color),
                if (showStatus) StatusBadge(label: report.status.label,
                    color: report.status.color),
              ]),
            ]),
          ),
        ),
      );
}
