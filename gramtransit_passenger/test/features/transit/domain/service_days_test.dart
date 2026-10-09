import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';

void main() {
  group('ServiceDays', () {
    test('operating day matches', () {
      const weekdaysOnly = ServiceDays(
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
      );

      // 2026-10-12 is a Monday
      final monday = DateTime(2026, 10, 12);
      expect(weekdaysOnly.operatesOn(monday), isTrue);
    });

    test('non-operating day does not match', () {
      const weekdaysOnly = ServiceDays(
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
      );

      // 2026-10-11 is a Sunday
      final sunday = DateTime(2026, 10, 11);
      expect(weekdaysOnly.operatesOn(sunday), isFalse);
    });

    test('equality', () {
      const s1 = ServiceDays(monday: true);
      const s2 = ServiceDays(monday: true);
      const s3 = ServiceDays(tuesday: true);

      expect(s1, s2);
      expect(s1, isNot(s3));
    });
  });
}
