import 'package:flutter_test/flutter_test.dart';
import 'package:risk_track/utils/constants.dart';
import 'package:risk_track/utils/helpers.dart';

void main() {
  test('nearby distance uses kilometres and handles same point', () {
    expect(AppHelpers.distanceKm(6.5244, 3.3792, 6.5244, 3.3792),
      closeTo(0, 0.001));
    expect(AppHelpers.distanceKm(0, 0, 0, 1), closeTo(111.19, .1));
  });

  test('status labels distinguish submitted from verified reports', () {
    expect(VerificationStatus.fromValue('pending').label,
      'Pending Verification');
    expect(VerificationStatus.fromValue('verified').label,
      'Verified Report');
    expect(VerificationStatus.fromValue('rejected').label,
      'Rejected Report');
    expect(ReportStatus.fromValue('resolved').label, 'Resolved');
    expect(RiskCategory.values.length, 8);
  });
}
