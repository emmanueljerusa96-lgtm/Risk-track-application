import 'package:flutter_test/flutter_test.dart';
import 'package:risk_track/services/mock_store.dart';
import 'package:risk_track/utils/constants.dart';
import 'package:risk_track/utils/helpers.dart';

void main() {
  final store = MockStore.instance;

  test('sample accounts and Lagos reports are ready', () async {
    final reports = await store.watchReports().first;
    expect(reports.map((report) => report.reportId), contains('sample-flood'));
    expect(reports.any((report) => report.verificationStatus == VerificationStatus.verified),
      isTrue);
    expect(reports.any((report) => report.status == ReportStatus.resolved), isTrue);
    store.signInSampleMember();
    expect(store.currentUser?.email, SampleAccounts.memberEmail);
    expect(await store.watchProfile('user-ada').first, isNotNull);
  });

  test('wrong password is rejected and a new report stays on the device', () async {
    expect(() => store.signIn(email: SampleAccounts.memberEmail, password: 'nope'),
      throwsA(isA<AuthFailure>()));
    store.signIn(
      email: SampleAccounts.adminEmail, password: SampleAccounts.adminPassword,
    );
    final id = store.newReportId();
    await store.createReport(
      reportId: id, userId: 'user-admin', title: 'Loose slab',
      description: 'A paving slab is rocking near the junction.',
      category: RiskCategory.roadHazard, latitude: 6.45, longitude: 3.40,
      address: 'Lagos Island', imageUrl: '',
    );
    final saved = await store.watchReport(id).first;
    expect(saved?.verificationStatus, VerificationStatus.pending);
    expect(store.flagReport(reportId: id, uid: 'user-ada', reason: 'Already fixed'),
      isTrue);
    expect(store.flagReport(reportId: id, uid: 'user-ada', reason: 'Again'), isFalse);
    store.reviewReport(id, verification: VerificationStatus.verified);
    expect((await store.watchReport(id).first)?.isVerified, isTrue);
    final notes = await store.watchNotifications('user-admin').first;
    expect(notes.any((note) => note.reportId == id), isTrue);
  });
}
