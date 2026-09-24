import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_track/models/risk_report_model.dart';
import 'package:risk_track/utils/constants.dart';
import 'package:risk_track/widgets/risk_card.dart';

void main() {
  testWidgets('a pending community report is not labelled verified',
      (tester) async {
    final report = RiskReportModel(
      reportId: 'r1', userId: 'u1', title: 'Road damaged near bridge',
      description: 'There is a damaged section of the road near the bridge.',
      category: RiskCategory.roadHazard, latitude: 6.5, longitude: 3.3,
      address: 'Bridge Road', imageUrl: '', status: ReportStatus.active,
      verificationStatus: VerificationStatus.pending,
      createdAt: DateTime.now(), updatedAt: DateTime.now(),
      reporterName: 'A member',
    );
    var opened = false;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RiskCard(
      report: report, onTap: () => opened = true,
    ))));
    expect(find.text('Pending Verification'), findsOneWidget);
    expect(find.text('Verified Report'), findsNothing);
    await tester.tap(find.text('Road damaged near bridge'));
    expect(opened, true);
  });
}
