import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/route_catalog.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// Immutable application projection representing details for a stop.
final class StopDetails {
  final TransitStop stop;
  final List<TransitRoute> routes;

  StopDetails({required this.stop, required Iterable<TransitRoute> routes})
    : routes = List.unmodifiable(routes);
}

/// Immutable application projection representing details for a route.
final class RouteDetails {
  final TransitRoute route;
  final List<RouteVariant> variants;

  RouteDetails({required this.route, required Iterable<RouteVariant> variants})
    : variants = List.unmodifiable(variants);
}

TransitStop? _findStop(List<TransitStop> stops, StopId stopId) {
  for (final stop in stops) {
    if (stop.id == stopId) {
      return stop;
    }
  }
  return null;
}

TransitRoute? _findRoute(List<TransitRoute> routes, RouteId routeId) {
  for (final route in routes) {
    if (route.id == routeId) {
      return route;
    }
  }
  return null;
}

/// Asynchronously resolves [StopDetails] for a given [StopId] from [timetableProvider].
///
/// Returns [AsyncData(null)] when [stopId] does not exist in the timetable.
/// Preserves [AsyncLoading] and [AsyncError] from [timetableProvider].
final stopDetailsProvider = Provider.autoDispose
    .family<AsyncValue<StopDetails?>, StopId>((ref, stopId) {
      final timetableAsync = ref.watch(timetableProvider);

      if (timetableAsync.hasError) {
        return AsyncError<StopDetails?>(
          timetableAsync.error!,
          timetableAsync.stackTrace!,
        );
      } else if (timetableAsync.isLoading || !timetableAsync.hasValue) {
        return const AsyncLoading<StopDetails?>();
      }

      final timetable = timetableAsync.requireValue;
      final stop = _findStop(timetable.stops, stopId);
      if (stop == null) {
        return const AsyncData<StopDetails?>(null);
      }

      final routes = routesServingStop(timetable, stopId);
      return AsyncData<StopDetails?>(StopDetails(stop: stop, routes: routes));
    }, name: 'stopDetailsProvider');

/// Asynchronously resolves [RouteDetails] for a given [RouteId] from [timetableProvider].
///
/// Returns [AsyncData(null)] when [routeId] does not exist in the timetable.
/// Preserves [AsyncLoading] and [AsyncError] from [timetableProvider].
final routeDetailsProvider = Provider.autoDispose
    .family<AsyncValue<RouteDetails?>, RouteId>((ref, routeId) {
      final timetableAsync = ref.watch(timetableProvider);

      if (timetableAsync.hasError) {
        return AsyncError<RouteDetails?>(
          timetableAsync.error!,
          timetableAsync.stackTrace!,
        );
      } else if (timetableAsync.isLoading || !timetableAsync.hasValue) {
        return const AsyncLoading<RouteDetails?>();
      }

      final timetable = timetableAsync.requireValue;
      final route = _findRoute(timetable.routes, routeId);
      if (route == null) {
        return const AsyncData<RouteDetails?>(null);
      }

      final variants = routeVariants(timetable, routeId);
      return AsyncData<RouteDetails?>(
        RouteDetails(route: route, variants: variants),
      );
    }, name: 'routeDetailsProvider');
