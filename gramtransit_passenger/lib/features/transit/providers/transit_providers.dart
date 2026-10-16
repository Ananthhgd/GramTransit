import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logging_providers.dart';
import '../../../core/time/time_providers.dart';
import '../data/bundled_timetable_repository.dart';
import '../domain/ids.dart';
import '../domain/scheduled_journey.dart';
import '../domain/stop_search.dart';
import '../domain/timetable_repository.dart';
import '../domain/transit_models.dart';
import '../domain/trip_occurrence.dart';
import '../domain/upcoming_trips_logic.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>(
  (ref) => BundledTimetableRepository(
    bundle: rootBundle,
    logger: ref.watch(appLoggerProvider),
  ),
  name: 'timetableRepositoryProvider',
);

final timetableProvider = FutureProvider<Timetable>(
  (ref) => ref.watch(timetableRepositoryProvider).loadTimetable(),
  name: 'timetableProvider',
  retry: (_, _) => null,
);

final upcomingTripsProvider = Provider.autoDispose
    .family<AsyncValue<UpcomingTrips>, StopId>((ref, stopId) {
      final timetableAsync = ref.watch(timetableProvider);
      final tickerAsync = ref.watch(minuteTickerProvider);

      if (timetableAsync.hasError) {
        return AsyncError<UpcomingTrips>(
          timetableAsync.error!,
          timetableAsync.stackTrace!,
        );
      } else if (tickerAsync.hasError) {
        return AsyncError<UpcomingTrips>(
          tickerAsync.error!,
          tickerAsync.stackTrace!,
        );
      } else if (!timetableAsync.hasValue || !tickerAsync.hasValue) {
        return const AsyncLoading<UpcomingTrips>();
      }

      try {
        final upcoming = findUpcomingTrips(
          stopId: stopId,
          timetable: timetableAsync.requireValue,
          now: tickerAsync.requireValue,
        );
        return AsyncData<UpcomingTrips>(upcoming);
      } catch (e, st) {
        return AsyncError<UpcomingTrips>(e, st);
      }
    }, name: 'upcomingTripsProvider');

/// Immutable parameter key for [stopSearchProvider].
final class StopSearchQuery {
  final String query;
  final StopId? excludedStopId;

  const StopSearchQuery({required this.query, this.excludedStopId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StopSearchQuery &&
          runtimeType == other.runtimeType &&
          query == other.query &&
          excludedStopId == other.excludedStopId;

  @override
  int get hashCode => Object.hash(query, excludedStopId);

  @override
  String toString() =>
      'StopSearchQuery(query: $query, excludedStopId: $excludedStopId)';
}

/// Immutable parameter key for [upcomingJourneysProvider].
final class JourneyQuery {
  final StopId boardingStopId;
  final StopId alightingStopId;

  const JourneyQuery({
    required this.boardingStopId,
    required this.alightingStopId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JourneyQuery &&
          runtimeType == other.runtimeType &&
          boardingStopId == other.boardingStopId &&
          alightingStopId == other.alightingStopId;

  @override
  int get hashCode => Object.hash(boardingStopId, alightingStopId);

  @override
  String toString() =>
      'JourneyQuery(boardingStopId: $boardingStopId, alightingStopId: $alightingStopId)';
}

/// Asynchronously searches stops against the loaded timetable.
///
/// Preserves [AsyncLoading] and [AsyncError] from [timetableProvider].
final stopSearchProvider = Provider.autoDispose
    .family<AsyncValue<List<TransitStop>>, StopSearchQuery>((ref, query) {
      final timetableAsync = ref.watch(timetableProvider);
      return timetableAsync.whenData(
        (timetable) => searchStops(
          timetable: timetable,
          query: query.query,
          excludedStopId: query.excludedStopId,
        ),
      );
    }, name: 'stopSearchProvider');

/// Provides direct upcoming scheduled journeys from boarding stop to alighting stop.
///
/// Combines [timetableProvider] and [minuteTickerProvider] using the exact same
/// minute-boundary reactive recomputation and no-flicker behavior as [upcomingTripsProvider].
final upcomingJourneysProvider = Provider.autoDispose
    .family<AsyncValue<UpcomingJourneys>, JourneyQuery>((ref, query) {
      final timetableAsync = ref.watch(timetableProvider);
      final tickerAsync = ref.watch(minuteTickerProvider);

      if (timetableAsync.hasError) {
        return AsyncError<UpcomingJourneys>(
          timetableAsync.error!,
          timetableAsync.stackTrace!,
        );
      } else if (tickerAsync.hasError) {
        return AsyncError<UpcomingJourneys>(
          tickerAsync.error!,
          tickerAsync.stackTrace!,
        );
      } else if (!timetableAsync.hasValue || !tickerAsync.hasValue) {
        return const AsyncLoading<UpcomingJourneys>();
      }

      try {
        final upcoming = findUpcomingJourneys(
          boardingStopId: query.boardingStopId,
          alightingStopId: query.alightingStopId,
          timetable: timetableAsync.requireValue,
          now: tickerAsync.requireValue,
        );
        return AsyncData<UpcomingJourneys>(upcoming);
      } catch (e, st) {
        return AsyncError<UpcomingJourneys>(e, st);
      }
    }, name: 'upcomingJourneysProvider');
