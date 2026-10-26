import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

/// Pure immutable domain model representing a passenger's saved stops and routes.
///
/// Encapsulates ordered, duplicate-free lists of [StopId] and [RouteId] values.
/// Preserves save order (oldest saved item first, new unique items appended last).
final class SavedTransit {
  SavedTransit({
    Iterable<StopId> stopIds = const <StopId>[],
    Iterable<RouteId> routeIds = const <RouteId>[],
  }) : stopIds = List<StopId>.unmodifiable(_deduplicate(stopIds)),
       routeIds = List<RouteId>.unmodifiable(_deduplicate(routeIds));

  const SavedTransit.empty()
    : stopIds = const <StopId>[],
      routeIds = const <RouteId>[];

  final List<StopId> stopIds;
  final List<RouteId> routeIds;

  static List<T> _deduplicate<T>(Iterable<T> items) {
    final seen = <T>{};
    final result = <T>[];
    for (final item in items) {
      if (seen.add(item)) {
        result.add(item);
      }
    }
    return result;
  }

  /// Returns true if [stopId] is currently saved.
  bool containsStop(StopId stopId) => stopIds.contains(stopId);

  /// Returns true if [routeId] is currently saved.
  bool containsRoute(RouteId routeId) => routeIds.contains(routeId);

  /// Returns a [SavedTransit] containing [stopId].
  ///
  /// If [stopId] is already present, returns `this` without modification.
  /// Otherwise, appends [stopId] to the end of the saved stops list.
  SavedTransit withStop(StopId stopId) {
    if (containsStop(stopId)) return this;
    return SavedTransit(stopIds: [...stopIds, stopId], routeIds: routeIds);
  }

  /// Returns a [SavedTransit] without [stopId].
  ///
  /// If [stopId] is not present, returns `this` without modification.
  /// Otherwise, removes [stopId] while preserving the order of other saved stops.
  SavedTransit withoutStop(StopId stopId) {
    if (!containsStop(stopId)) return this;
    return SavedTransit(
      stopIds: stopIds.where((id) => id != stopId),
      routeIds: routeIds,
    );
  }

  /// Returns a [SavedTransit] containing [routeId].
  ///
  /// If [routeId] is already present, returns `this` without modification.
  /// Otherwise, appends [routeId] to the end of the saved routes list.
  SavedTransit withRoute(RouteId routeId) {
    if (containsRoute(routeId)) return this;
    return SavedTransit(stopIds: stopIds, routeIds: [...routeIds, routeId]);
  }

  /// Returns a [SavedTransit] without [routeId].
  ///
  /// If [routeId] is not present, returns `this` without modification.
  /// Otherwise, removes [routeId] while preserving the order of other saved routes.
  SavedTransit withoutRoute(RouteId routeId) {
    if (!containsRoute(routeId)) return this;
    return SavedTransit(
      stopIds: stopIds,
      routeIds: routeIds.where((id) => id != routeId),
    );
  }
}
