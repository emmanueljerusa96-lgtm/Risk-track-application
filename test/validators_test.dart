import 'package:flutter_test/flutter_test.dart';
import 'package:risk_track/utils/validators.dart';

void main() {
  test('registration fields reject invalid values', () {
    expect(Validators.fullName('A'), isNotNull);
    expect(Validators.fullName(' Ada Lovelace '), isNull);
    expect(Validators.email('not-an-email'), isNotNull);
    expect(Validators.email('member@example.org'), isNull);
    expect(Validators.password('short'), isNotNull);
    expect(Validators.password('long enough'), isNull);
  });

  test('report fields enforce substantive descriptions', () {
    expect(Validators.title('Hey'), isNotNull);
    expect(Validators.title('Flooded crossing'), isNull);
    expect(Validators.description('Too short'), isNotNull);
    expect(Validators.description('Water is covering the roadway this morning.'),
      isNull);
    expect(Validators.flagReason('bad'), isNotNull);
    expect(Validators.flagReason('This road has been repaired.'), isNull);
  });
}
