import 'package:flutter_test/flutter_test.dart';
import 'package:risk_track/services/analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('analytics calls do nothing before Firebase is configured', () async {
    await AnalyticsService.instance.logLogin();
    await AnalyticsService.instance.logSignUp();
    await AnalyticsService.instance.logReportSubmitted('flood');
    await AnalyticsService.instance.logScreen('LoginScreen');
    await AnalyticsService.instance.logScreen(null);
    await AnalyticsService.instance.applyPreference();
  });
}
