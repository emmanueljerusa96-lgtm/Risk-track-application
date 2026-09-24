import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:risk_track/screens/login_screen.dart';

void main() {
  testWidgets('invalid login does not contact Firebase', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.ensureVisible(find.text('Sign in').last);
    await tester.tap(find.text('Sign in').last);
    await tester.pump();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });
}
