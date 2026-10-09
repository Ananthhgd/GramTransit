import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

void main() {
  group('Typed IDs', () {
    test('StopId equality', () {
      final id1 = StopId('stop1');
      final id2 = StopId('stop1');
      final id3 = StopId('stop2');

      expect(id1, id2);
      expect(id1.hashCode, id2.hashCode);
      expect(id1, isNot(id3));
      expect(id1.toString(), 'stop1');
    });

    test('Inequality between different ID types', () {
      final stopId = StopId('123');
      final routeId = RouteId('123');
      final tripId = TripId('123');

      expect(stopId, isNot(routeId));
      expect(stopId, isNot(tripId));
      expect(routeId, isNot(tripId));
    });

    test('Invalid values throw ArgumentError', () {
      expect(() => StopId(''), throwsArgumentError);
      expect(() => StopId('   '), throwsArgumentError);
      expect(() => RouteId(''), throwsArgumentError);
      expect(() => TripId(''), throwsArgumentError);
    });
  });
}
