import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';

void main() {
  group('ServiceTime', () {
    test('valid bounds (00:00, 23:59, 24:00, 25:10, 47:59)', () {
      final t0 = ServiceTime(hour: 0, minute: 0);
      expect(t0.toString(), '00:00');

      final t2359 = ServiceTime(hour: 23, minute: 59);
      expect(t2359.toString(), '23:59');

      final t2400 = ServiceTime(hour: 24, minute: 0);
      expect(t2400.toString(), '24:00');

      final t2510 = ServiceTime(hour: 25, minute: 10);
      expect(t2510.toString(), '25:10');

      final t4759 = ServiceTime(hour: 47, minute: 59);
      expect(t4759.toString(), '47:59');
    });

    test('invalid values throw ArgumentError', () {
      expect(() => ServiceTime(hour: -1, minute: 0), throwsArgumentError);
      expect(() => ServiceTime(hour: 48, minute: 0), throwsArgumentError);
      expect(() => ServiceTime(hour: 12, minute: -1), throwsArgumentError);
      expect(() => ServiceTime(hour: 12, minute: 60), throwsArgumentError);
    });

    test('conversion to actual DateTime relative to a service date', () {
      final serviceDate = DateTime(2026, 10, 15);

      // 08:30 on same day
      final dt1 = ServiceTime(hour: 8, minute: 30).toDateTime(serviceDate);
      expect(dt1, DateTime(2026, 10, 15, 8, 30));

      // 25:10 crosses into next day (Oct 16, 01:10)
      final dt2 = ServiceTime(hour: 25, minute: 10).toDateTime(serviceDate);
      expect(dt2, DateTime(2026, 10, 16, 1, 10));
    });

    test('equality and comparison', () {
      final t1 = ServiceTime(hour: 25, minute: 10);
      final t2 = ServiceTime.parse('25:10');
      final t3 = ServiceTime(hour: 25, minute: 11);

      expect(t1, t2);
      expect(t1.compareTo(t2), 0);
      expect(t1.compareTo(t3), -1);
      expect(t3.compareTo(t1), 1);
    });
  });
}
