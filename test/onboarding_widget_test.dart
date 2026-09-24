import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_track/screens/onboarding_screen.dart';

void main() {
  testWidgets('three onboarding pages introduce the community features',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));
    expect(find.text('Discover Reported Risks'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Report Risky Locations'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Help Your Community Stay Aware'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
