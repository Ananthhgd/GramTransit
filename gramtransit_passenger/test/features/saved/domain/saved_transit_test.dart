import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/features/saved/domain/saved_transit.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

void main() {
  final stop1 = StopId('stop_1');
  final stop2 = StopId('stop_2');
  final stop3 = StopId('stop_3');

  final route1 = RouteId('route_1');
  final route2 = RouteId('route_2');
  final route3 = RouteId('route_3');

  group('SavedTransit domain model', () {
    test('1. empty SavedTransit exposes empty stop and route lists', () {
      const emptyConst = SavedTransit.empty();
      expect(emptyConst.stopIds, isEmpty);
      expect(emptyConst.routeIds, isEmpty);

      final emptyDefault = SavedTransit();
      expect(emptyDefault.stopIds, isEmpty);
      expect(emptyDefault.routeIds, isEmpty);
    });

    test('2. input list immutability / defensive copy', () {
      final inputStops = [stop1, stop2];
      final inputRoutes = [route1];

      final saved = SavedTransit(stopIds: inputStops, routeIds: inputRoutes);

      inputStops.add(stop3);
      inputRoutes.add(route2);

      expect(saved.stopIds, equals([stop1, stop2]));
      expect(saved.routeIds, equals([route1]));
    });

    test('3. exposed lists cannot be mutated', () {
      final saved = SavedTransit(stopIds: [stop1], routeIds: [route1]);

      expect(() => saved.stopIds.add(stop2), throwsUnsupportedError);
      expect(() => saved.stopIds.clear(), throwsUnsupportedError);
      expect(() => saved.routeIds.add(route2), throwsUnsupportedError);
      expect(() => saved.routeIds.clear(), throwsUnsupportedError);

      const emptyConst = SavedTransit.empty();
      expect(() => emptyConst.stopIds.add(stop1), throwsUnsupportedError);
      expect(() => emptyConst.routeIds.add(route1), throwsUnsupportedError);
    });

    test('4. constructor duplicate normalization preserves first occurrence and original order', () {
      final duplicateStops = [stop3, stop1, stop2, stop1, stop3, stop2];
      final duplicateRoutes = [route2, route1, route2, route3, route1];

      final saved = SavedTransit(
        stopIds: duplicateStops,
        routeIds: duplicateRoutes,
      );

      // Duplicate StopIds normalized preserving first occurrence and original order (not sorted)
      expect(saved.stopIds, equals([stop3, stop1, stop2]));
      // Duplicate RouteIds normalized preserving first occurrence and original order (not sorted)
      expect(saved.routeIds, equals([route2, route1, route3]));
    });

    test('5. containsStop returns correct membership', () {
      final saved = SavedTransit(stopIds: [stop1, stop2]);

      expect(saved.containsStop(stop1), isTrue);
      expect(saved.containsStop(stop2), isTrue);
      expect(saved.containsStop(stop3), isFalse);
    });

    test('6. containsRoute returns correct membership', () {
      final saved = SavedTransit(routeIds: [route1, route2]);

      expect(saved.containsRoute(route1), isTrue);
      expect(saved.containsRoute(route2), isTrue);
      expect(saved.containsRoute(route3), isFalse);
    });

    test('7. withStop appends new ID in save order', () {
      final initial = SavedTransit(stopIds: [stop1]);
      final updated = initial.withStop(stop2);

      expect(updated.stopIds, equals([stop1, stop2]));
      expect(initial.stopIds, equals([stop1])); // original unchanged
    });

    test('8. withStop existing is idempotent and returns this', () {
      final initial = SavedTransit(stopIds: [stop1, stop2]);
      final result = initial.withStop(stop1);

      expect(identical(result, initial), isTrue);
      expect(result.stopIds, equals([stop1, stop2]));
    });

    test('9. withoutStop removes target while preserving other order', () {
      final initial = SavedTransit(stopIds: [stop1, stop2, stop3]);
      final updated = initial.withoutStop(stop2);

      expect(updated.stopIds, equals([stop1, stop3]));
      expect(
        initial.stopIds,
        equals([stop1, stop2, stop3]),
      ); // original unchanged
    });

    test('10. withoutStop missing is idempotent and returns this', () {
      final initial = SavedTransit(stopIds: [stop1, stop2]);
      final result = initial.withoutStop(stop3);

      expect(identical(result, initial), isTrue);
      expect(result.stopIds, equals([stop1, stop2]));
    });

    test('11. equivalent route operations behave correctly', () {
      final initial = SavedTransit(routeIds: [route1]);

      // withRoute appends new ID
      final added = initial.withRoute(route2);
      expect(added.routeIds, equals([route1, route2]));
      expect(initial.routeIds, equals([route1]));

      // withRoute existing is idempotent
      final noOpAdd = added.withRoute(route1);
      expect(identical(noOpAdd, added), isTrue);
      expect(noOpAdd.routeIds, equals([route1, route2]));

      // withoutRoute removes target while preserving order
      final withThree = added.withRoute(route3);
      expect(withThree.routeIds, equals([route1, route2, route3]));
      final removed = withThree.withoutRoute(route2);
      expect(removed.routeIds, equals([route1, route3]));

      // withoutRoute missing is idempotent
      final noOpRemove = removed.withoutRoute(route2);
      expect(identical(noOpRemove, removed), isTrue);
      expect(noOpRemove.routeIds, equals([route1, route3]));
    });

    test('12. stop and route namespaces are independent', () {
      final sharedId = 'transit_item_42';
      final stopWithSharedId = StopId(sharedId);
      final routeWithSharedId = RouteId(sharedId);

      var state = const SavedTransit.empty();

      state = state.withStop(stopWithSharedId);
      expect(state.containsStop(stopWithSharedId), isTrue);
      expect(state.containsRoute(routeWithSharedId), isFalse);
      expect(state.stopIds, equals([stopWithSharedId]));
      expect(state.routeIds, isEmpty);

      state = state.withRoute(routeWithSharedId);
      expect(state.containsStop(stopWithSharedId), isTrue);
      expect(state.containsRoute(routeWithSharedId), isTrue);
      expect(state.stopIds, equals([stopWithSharedId]));
      expect(state.routeIds, equals([routeWithSharedId]));

      state = state.withoutStop(stopWithSharedId);
      expect(state.containsStop(stopWithSharedId), isFalse);
      expect(state.containsRoute(routeWithSharedId), isTrue);
      expect(state.stopIds, isEmpty);
      expect(state.routeIds, equals([routeWithSharedId]));
    });
  });
}
