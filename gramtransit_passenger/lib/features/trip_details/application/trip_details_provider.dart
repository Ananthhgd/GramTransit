import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// The structural position of a stop within a scheduled trip's stop sequence.
enum TripStopPosition { first, intermediate, last }

/// Immutable application view-model representing a single stop in a trip's stop list.
@immutable
final class TripStopRow {
  const TripStopRow({
    required this.stopName,
    required this.arrival,
    required this.departure,
    required this.position,
  });

  final LocalizedText stopName;
  final ServiceTime arrival;
  final ServiceTime departure;
  final TripStopPosition position;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripStopRow &&
          runtimeType == other.runtimeType &&
          stopName == other.stopName &&
          arrival == other.arrival &&
          departure == other.departure &&
          position == other.position;

  @override
  int get hashCode => Object.hash(stopName, arrival, departure, position);
}

bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (a == null) return b == null;
  if (b == null || a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Immutable application view-model representing the complete details of a scheduled trip.
@immutable
final class TripDetails {
  TripDetails({
    required this.tripId,
    required this.routeShortName,
    required this.routeLongName,
    required this.serviceDays,
    required Iterable<TripStopRow> stops,
  }) : stops = List.unmodifiable(stops);

  final TripId tripId;
  final LocalizedText routeShortName;
  final LocalizedText routeLongName;
  final ServiceDays serviceDays;
  final List<TripStopRow> stops;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripDetails &&
          runtimeType == other.runtimeType &&
          tripId == other.tripId &&
          routeShortName == other.routeShortName &&
          routeLongName == other.routeLongName &&
          serviceDays == other.serviceDays &&
          _listEquals(stops, other.stops);

  @override
  int get hashCode => Object.hash(
    tripId,
    routeShortName,
    routeLongName,
    serviceDays,
    Object.hashAll(stops),
  );
}

ScheduledTrip? _findTrip(List<ScheduledTrip> trips, TripId tripId) {
  for (final trip in trips) {
    if (trip.id == tripId) {
      return trip;
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

TransitStop? _findStop(List<TransitStop> stops, StopId stopId) {
  for (final stop in stops) {
    if (stop.id == stopId) {
      return stop;
    }
  }
  return null;
}

/// Synchronous projection of [timetableProvider] for a specific [TripId].
///
/// Returns [AsyncData(null)] when [tripId] does not exist in the timetable.
/// Preserves [AsyncLoading] and [AsyncError] from [timetableProvider].
/// Yields an [AsyncError] wrapping a [DataFormatFailure] if a known trip
/// references a missing route or stop in the timetable.
final tripDetailsProvider = Provider.autoDispose
    .family<AsyncValue<TripDetails?>, TripId>((ref, tripId) {
      final timetableAsync = ref.watch(timetableProvider);

      if (timetableAsync.hasError) {
        return AsyncError<TripDetails?>(
          timetableAsync.error!,
          timetableAsync.stackTrace!,
        );
      } else if (timetableAsync.isLoading || !timetableAsync.hasValue) {
        return const AsyncLoading<TripDetails?>();
      }

      final timetable = timetableAsync.requireValue;
      final trip = _findTrip(timetable.trips, tripId);
      if (trip == null) {
        return const AsyncData<TripDetails?>(null);
      }

      final route = _findRoute(timetable.routes, trip.routeId);
      if (route == null) {
        return AsyncError<TripDetails?>(
          DataFormatFailure(
            cause:
                'Route ${trip.routeId} referenced by trip ${trip.id} not found in timetable',
          ),
          StackTrace.current,
        );
      }

      final rows = <TripStopRow>[];
      for (var i = 0; i < trip.stopTimes.length; i++) {
        final stopTime = trip.stopTimes[i];
        final stop = _findStop(timetable.stops, stopTime.stopId);
        if (stop == null) {
          return AsyncError<TripDetails?>(
            DataFormatFailure(
              cause:
                  'Stop ${stopTime.stopId} referenced by trip ${trip.id} not found in timetable',
            ),
            StackTrace.current,
          );
        }

        final TripStopPosition position;
        if (i == 0) {
          position = TripStopPosition.first;
        } else if (i == trip.stopTimes.length - 1) {
          position = TripStopPosition.last;
        } else {
          position = TripStopPosition.intermediate;
        }

        rows.add(
          TripStopRow(
            stopName: stop.name,
            arrival: stopTime.arrivalTime,
            departure: stopTime.departureTime,
            position: position,
          ),
        );
      }

      return AsyncData<TripDetails?>(
        TripDetails(
          tripId: trip.id,
          routeShortName: route.shortName,
          routeLongName: route.longName,
          serviceDays: trip.serviceDays,
          stops: rows,
        ),
      );
    }, name: 'tripDetailsProvider');
