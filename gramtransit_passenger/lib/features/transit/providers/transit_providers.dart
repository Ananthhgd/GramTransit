import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/logging/logging_providers.dart';
import '../../../core/time/time_providers.dart';
import '../data/bundled_timetable_repository.dart';
import '../domain/ids.dart';
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
