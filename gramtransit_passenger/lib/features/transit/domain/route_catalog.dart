import 'ids.dart';
import 'transit_models.dart';

/// Derived immutable grouping of trips belonging to a route that share
/// an identical ordered sequence of stops.
final class RouteVariant {
  final RouteId routeId;
  final List<StopId> stopIds;
  final List<ScheduledTrip> trips;

  RouteVariant({
    required this.routeId,
    required Iterable<StopId> stopIds,
    required Iterable<ScheduledTrip> trips,
  }) : stopIds = List.unmodifiable(stopIds),
       trips = List.unmodifiable(trips) {
    if (this.stopIds.length < 2) {
      throw ArgumentError('RouteVariant must contain at least 2 stops');
    }
    if (this.trips.isEmpty) {
      throw ArgumentError('RouteVariant must contain at least one trip');
    }
    for (final trip in this.trips) {
      if (trip.routeId != routeId) {
        throw ArgumentError(
          'Trip routeId (${trip.routeId}) does not match RouteVariant routeId ($routeId)',
        );
      }
      if (trip.stopTimes.length != this.stopIds.length) {
        throw ArgumentError(
          'Trip stop sequence length does not match RouteVariant stop sequence',
        );
      }
      for (var i = 0; i < this.stopIds.length; i++) {
        if (trip.stopTimes[i].stopId != this.stopIds[i]) {
          throw ArgumentError(
            'Trip stop sequence does not match RouteVariant stop sequence',
          );
        }
      }
    }
  }

  StopId get firstStopId => stopIds.first;

  StopId get lastStopId => stopIds.last;

  int get stopCount => stopIds.length;
}

final class _VariantBuilder {
  final List<StopId> stopIds;
  final List<ScheduledTrip> trips = [];

  _VariantBuilder(this.stopIds);

  bool matches(ScheduledTrip trip) {
    if (trip.stopTimes.length != stopIds.length) return false;
    for (var i = 0; i < stopIds.length; i++) {
      if (trip.stopTimes[i].stopId != stopIds[i]) return false;
    }
    return true;
  }
}

/// Derives the ordered list of [RouteVariant] groupings for [routeId] in [timetable].
///
/// Throws [ArgumentError] if [routeId] is not in [timetable.routes].
/// Returns an empty list if the route exists but has no scheduled trips.
/// Variant order follows the first appearance of any trip belonging to that variant
/// in canonical [timetable.trips] order.
/// Trips inside each variant are sorted by first-stop departure [ServiceTime]
/// (preserving late-night 24:xx–47:xx hours after 23:xx), tie-broken by [TripId.value].
List<RouteVariant> routeVariants(Timetable timetable, RouteId routeId) {
  final routeExists = timetable.routes.any((route) => route.id == routeId);
  if (!routeExists) {
    throw ArgumentError('Route not found in timetable');
  }

  final builders = <_VariantBuilder>[];

  for (final trip in timetable.trips) {
    if (trip.routeId != routeId) continue;

    _VariantBuilder? matchedBuilder;
    for (final builder in builders) {
      if (builder.matches(trip)) {
        matchedBuilder = builder;
        break;
      }
    }

    if (matchedBuilder != null) {
      matchedBuilder.trips.add(trip);
    } else {
      final stopIds = trip.stopTimes.map((st) => st.stopId).toList();
      final newBuilder = _VariantBuilder(stopIds);
      newBuilder.trips.add(trip);
      builders.add(newBuilder);
    }
  }

  if (builders.isEmpty) {
    return List<RouteVariant>.unmodifiable(const []);
  }

  final variants = <RouteVariant>[];
  for (final builder in builders) {
    final sortedTrips = List<ScheduledTrip>.of(builder.trips)
      ..sort((a, b) {
        final timeComparison = a.stopTimes.first.departureTime.compareTo(
          b.stopTimes.first.departureTime,
        );
        if (timeComparison != 0) {
          return timeComparison;
        }
        return a.id.value.compareTo(b.id.value);
      });

    variants.add(
      RouteVariant(
        routeId: routeId,
        stopIds: builder.stopIds,
        trips: sortedTrips,
      ),
    );
  }

  return List<RouteVariant>.unmodifiable(variants);
}

/// Derives the list of [TransitRoute]s that serve [stopId] in [timetable].
///
/// Throws [ArgumentError] if [stopId] is not in [timetable.stops].
/// Returns an empty list if the stop exists but is not visited by any scheduled trip.
/// A route serves a stop when at least one trip visits it as origin, intermediate,
/// or terminal stop.
/// Routes are deduplicated and returned in canonical [timetable.routes] order.
List<TransitRoute> routesServingStop(Timetable timetable, StopId stopId) {
  final stopExists = timetable.stops.any((stop) => stop.id == stopId);
  if (!stopExists) {
    throw ArgumentError('Stop not found in timetable');
  }

  final servingRouteIds = <RouteId>{};
  for (final trip in timetable.trips) {
    for (final stopTime in trip.stopTimes) {
      if (stopTime.stopId == stopId) {
        servingRouteIds.add(trip.routeId);
        break;
      }
    }
  }

  if (servingRouteIds.isEmpty) {
    return List<TransitRoute>.unmodifiable(const []);
  }

  final servingRoutes = timetable.routes
      .where((route) => servingRouteIds.contains(route.id))
      .toList();

  return List<TransitRoute>.unmodifiable(servingRoutes);
}
