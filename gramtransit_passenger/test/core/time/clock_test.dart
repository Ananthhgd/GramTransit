import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/time/clock.dart';

void main() {
  group('SystemClock', () {
    test('now() returns the current system time', () {
      const clock = SystemClock();
      final before = DateTime.now();
      final now = clock.now();
      final after = DateTime.now();

      // now should be >= before and <= after.
      expect(now.isBefore(before), isFalse);
      expect(now.isAfter(after), isFalse);
    });
  });
}
