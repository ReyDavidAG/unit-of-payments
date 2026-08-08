import 'package:flutter_test/flutter_test.dart';
import 'package:unit_of_payments/core/constants/environment.dart';

void main() {
  test('unconfigured build fails loudly at startup', () {
    // The test runner passes no --dart-define, so this is the missing-.env case.
    expect(Environment.isConfigured, isFalse);
    expect(Environment.assertConfigured, throwsStateError);
  });
}
