import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

abstract final class AppColors {
  static const ink = Color(0xFF17323B);
  static const teal = Color(0xFF087E74);
  static const deepTeal = Color(0xFF075F59);
  static const mint = Color(0xFFE5F5EE);
  static const canvas = Color(0xFFF6F8F7);
  static const muted = Color(0xFF657780);
  static const coral = Color(0xFFC56451);
  static const amber = Color(0xFFBA751E);
  static const border = Color(0xFFDFE8E4);
}

abstract final class AppConstants {
  static const appName = 'Risk Track';
  static const tagline = 'Track. Report. Stay Aware.';
  static const disclaimer =
      'Community reports are submitted by people, not official safety alerts. '
      'Pending reports are unverified. Exercise judgment, check official sources '
      'for important decisions, and call local emergency services if needed.';
  static const mapUserAgent = 'com.risktrack.app';
  static const mapTiles = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const mapAttribution = '© OpenStreetMap contributors';
  static const mapAttributionUrl = 'https://www.openstreetmap.org/copyright';
  // Starting viewport only; location is NEVER obtained before an explicit tap.
  static const initialMapCenter = LatLng(6.5244, 3.3792);
  static const maxImageBytes = 5 * 1024 * 1024;
  static const resultsLimit = 100;
}

enum RiskCategory {
  roadHazard('Road Hazard', Icons.construction_outlined, Color(0xFFE49D38)),
  flood('Flood', Icons.water_drop_outlined, Color(0xFF398BBF)),
  security('Security', Icons.shield_outlined, Color(0xFF9A69B5)),
  fire('Fire', Icons.local_fire_department_outlined, Color(0xFFE3794E)),
  accident('Accident', Icons.car_crash_outlined, Color(0xFFD66561)),
  poorLighting('Poor Lighting', Icons.lightbulb_outline, Color(0xFF907EB5)),
  environmental('Environmental', Icons.eco_outlined, Color(0xFF5A9B68)),
  other('Other', Icons.info_outline, Color(0xFF71858C));

  const RiskCategory(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;

  static RiskCategory fromLabel(String? value) {
    for (final category in values) {
      if (category.label == value) return category;
    }
    return other;
  }
}

enum ReportStatus {
  active('active', 'Active', AppColors.teal),
  resolved('resolved', 'Resolved', Color(0xFF438862));

  const ReportStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static ReportStatus fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return active;
  }
}

enum VerificationStatus {
  pending('pending', 'Pending Verification', AppColors.amber),
  verified('verified', 'Verified Report', AppColors.teal),
  rejected('rejected', 'Rejected Report', AppColors.coral);

  const VerificationStatus(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;

  static VerificationStatus fromValue(String? value) {
    for (final status in values) {
      if (status.value == value) return status;
    }
    return pending;
  }
}
