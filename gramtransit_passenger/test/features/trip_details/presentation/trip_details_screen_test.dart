import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/app/router/app_routes.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/trip_details_screen.dart';

import '../trip_details_test_support.dart';

void main() {
  group('TripDetailsScreen', () {
    testWidgets('1. loading shows loading view and app bar', (tester) async {
      final completer = Completer<Timetable>();
      final fakeRepo = FakeTripDetailsTimetableRepository(completer: completer);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      expect(find.text('Trip details'), findsOneWidget);
      expect(find.byType(GtLoadingView), findsOneWidget);

      completer.complete(createTripDetailsTestTimetable());
      await tester.pumpAndSettle();
    });

    testWidgets('2. DataFormatFailure-friendly error is rendered', (
      tester,
    ) async {
      final failure = DataFormatFailure(cause: 'Corrupted timetable format');
      final fakeRepo = FakeTripDetailsTimetableRepository(error: failure);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip details'), findsOneWidget);
      expect(find.byType(GtErrorView), findsOneWidget);
      expect(
        find.text('The timetable data could not be loaded.'),
        findsOneWidget,
      );
      expect(find.textContaining('Corrupted timetable format'), findsNothing);
    });

    testWidgets('3. generic error is rendered with fallback message', (
      tester,
    ) async {
      final error = Exception('Disk error');
      final fakeRepo = FakeTripDetailsTimetableRepository(error: error);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip details'), findsOneWidget);
      expect(find.byType(GtErrorView), findsOneWidget);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('Disk error'), findsNothing);
    });

    testWidgets('4. retry causes timetable reload/refresh', (tester) async {
      final fakeRepo = FakeTripDetailsTimetableRepository(
        error: const UnexpectedFailure(),
      );

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(fakeRepo.loadCount, 1);
      expect(find.byType(GtErrorView), findsOneWidget);

      fakeRepo.error = null;
      fakeRepo.timetable = createTripDetailsTestTimetable();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(fakeRepo.loadCount, 2);
      expect(find.byType(GtErrorView), findsNothing);
      expect(find.text('Route 101'), findsOneWidget);
    });

    testWidgets('5. unknown trip -> Trip not found empty state', (
      tester,
    ) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('unknown_trip')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip details'), findsOneWidget);
      expect(find.byType(GtEmptyState), findsOneWidget);
      expect(find.text('Trip not found'), findsOneWidget);
      expect(
        find.text("This trip isn't in the current timetable."),
        findsOneWidget,
      );
      expect(find.text('Go to Home'), findsOneWidget);
    });

    testWidgets('6. Go to Home action navigates to Home', (tester) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);
      var navigatedToHome = false;

      final testRouter = GoRouter(
        initialLocation: '/trips/unknown',
        routes: [
          GoRoute(
            path: '/home',
            name: AppRoutes.home,
            builder: (context, state) {
              navigatedToHome = true;
              return const Scaffold(body: Text('Home Screen Test'));
            },
          ),
          GoRoute(
            path: '/trips/:tripId',
            name: 'tripDetailsTest',
            builder: (context, state) =>
                TripDetailsScreen(tripId: TripId('unknown')),
          ),
        ],
      );

      await pumpTripDetailsTest(
        tester,
        router: testRouter,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Go to Home'), findsOneWidget);
      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();

      expect(navigatedToHome, isTrue);
      expect(find.text('Home Screen Test'), findsOneWidget);
    });

    testWidgets('7. found trip header renders route and endpoints', (
      tester,
    ) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // 8. route short/long names
      expect(find.text('Route 101'), findsOneWidget);
      expect(find.text('City Center to North Station'), findsOneWidget);

      // 9. origin -> destination
      expect(find.text('City Center → North Station'), findsOneWidget);
    });

    testWidgets(
      '10. Runs Mon, Tue... ordering is Monday-first without ranges',
      (tester) async {
        final timetable = createTripDetailsTestTimetable(
          trips: [
            ScheduledTrip(
              id: TripId('trip_custom_days'),
              routeId: RouteId('route_1'),
              serviceDays: const ServiceDays(
                monday: true,
                wednesday: true,
                friday: true,
              ),
              stopTimes: [
                StopTime(
                  stopId: StopId('stop_1'),
                  arrivalTime: ServiceTime(hour: 8, minute: 0),
                  departureTime: ServiceTime(hour: 8, minute: 5),
                ),
                StopTime(
                  stopId: StopId('stop_2'),
                  arrivalTime: ServiceTime(hour: 8, minute: 20),
                  departureTime: ServiceTime(hour: 8, minute: 25),
                ),
              ],
            ),
          ],
        );
        final fakeRepo = FakeTripDetailsTimetableRepository(
          timetable: timetable,
        );

        await pumpTripDetailsTest(
          tester,
          child: TripDetailsScreen(tripId: TripId('trip_custom_days')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.text('Runs Mon, Wed, Fri'), findsOneWidget);
      },
    );

    testWidgets('11. Runs every day when all seven days are active', (
      tester,
    ) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Runs every day'), findsOneWidget);
    });

    testWidgets('12. scheduled-times disclosure note is visible', (
      tester,
    ) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Scheduled times. Actual times may vary.'),
        findsOneWidget,
      );
    });

    testWidgets('13. Scheduled stop times heading is visible', (tester) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Scheduled stop times'), findsOneWidget);
    });

    testWidgets('14. first stop -> First stop badge and departure only', (
      tester,
    ) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('First stop'), findsOneWidget);
      expect(find.text('Departs 8:05 AM'), findsOneWidget);
    });

    testWidgets('15. last stop -> Last stop badge and arrival only', (
      tester,
    ) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Last stop'), findsOneWidget);
      expect(find.text('Arrives 8:30 AM'), findsOneWidget);
    });

    testWidgets(
      '16. intermediate equal arrival/departure -> single clock time',
      (tester) async {
        final timetable = createTripDetailsTestTimetable();
        final fakeRepo = FakeTripDetailsTimetableRepository(
          timetable: timetable,
        );

        await pumpTripDetailsTest(
          tester,
          child: TripDetailsScreen(tripId: TripId('trip_1')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Intermediate stop Market Square has arrival 8:15 and departure 8:15
        expect(find.text('Market Square'), findsOneWidget);
        expect(find.text('8:15 AM'), findsOneWidget);
      },
    );

    testWidgets(
      '17. intermediate differing arrival/departure -> both arrives and departs',
      (tester) async {
        final timetable = createTripDetailsTestTimetable(
          trips: [
            ScheduledTrip(
              id: TripId('trip_diff_times'),
              routeId: RouteId('route_1'),
              serviceDays: const ServiceDays(monday: true),
              stopTimes: [
                StopTime(
                  stopId: StopId('stop_1'),
                  arrivalTime: ServiceTime(hour: 8, minute: 0),
                  departureTime: ServiceTime(hour: 8, minute: 5),
                ),
                StopTime(
                  stopId: StopId('stop_2'),
                  arrivalTime: ServiceTime(hour: 8, minute: 15),
                  departureTime: ServiceTime(hour: 8, minute: 20),
                ),
                StopTime(
                  stopId: StopId('stop_3'),
                  arrivalTime: ServiceTime(hour: 8, minute: 40),
                  departureTime: ServiceTime(hour: 8, minute: 45),
                ),
              ],
            ),
          ],
        );
        final fakeRepo = FakeTripDetailsTimetableRepository(
          timetable: timetable,
        );

        await pumpTripDetailsTest(
          tester,
          child: TripDetailsScreen(tripId: TripId('trip_diff_times')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.text('Arrives 8:15 AM'), findsOneWidget);
        expect(find.text('Departs 8:20 AM'), findsOneWidget);
      },
    );

    testWidgets(
      '18. 24:10 -> normalized 00:10 / 12-hour equivalent (12:10 AM) + +1 marker',
      (tester) async {
        final timetable = createTripDetailsTestTimetable(
          trips: [
            ScheduledTrip(
              id: TripId('trip_next_day'),
              routeId: RouteId('route_1'),
              serviceDays: const ServiceDays(monday: true),
              stopTimes: [
                StopTime(
                  stopId: StopId('stop_1'),
                  arrivalTime: ServiceTime(hour: 23, minute: 50),
                  departureTime: ServiceTime(hour: 23, minute: 55),
                ),
                StopTime(
                  stopId: StopId('stop_2'),
                  arrivalTime: ServiceTime(hour: 24, minute: 10),
                  departureTime: ServiceTime(hour: 24, minute: 10),
                ),
              ],
            ),
          ],
        );
        final fakeRepo = FakeTripDetailsTimetableRepository(
          timetable: timetable,
        );

        await pumpTripDetailsTest(
          tester,
          child: TripDetailsScreen(tripId: TripId('trip_next_day')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // 24:10 normalized in 12-hour is 12:10 AM with a visible +1 marker on last stop
        expect(find.text('Arrives 12:10 AM'), findsOneWidget);
        expect(find.text('+1'), findsOneWidget);
      },
    );

    testWidgets(
      '19. next-day semantics communicate next day in screen reader label',
      (tester) async {
        final timetable = createTripDetailsTestTimetable(
          trips: [
            ScheduledTrip(
              id: TripId('trip_next_day_sem'),
              routeId: RouteId('route_1'),
              serviceDays: const ServiceDays(monday: true),
              stopTimes: [
                StopTime(
                  stopId: StopId('stop_1'),
                  arrivalTime: ServiceTime(hour: 23, minute: 50),
                  departureTime: ServiceTime(hour: 23, minute: 55),
                ),
                StopTime(
                  stopId: StopId('stop_2'),
                  arrivalTime: ServiceTime(hour: 24, minute: 10),
                  departureTime: ServiceTime(hour: 24, minute: 10),
                ),
              ],
            ),
          ],
        );
        final fakeRepo = FakeTripDetailsTimetableRepository(
          timetable: timetable,
        );

        await pumpTripDetailsTest(
          tester,
          child: TripDetailsScreen(tripId: TripId('trip_next_day_sem')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(RegExp('next day', caseSensitive: false)),
          findsAtLeastNWidgets(1),
        );
      },
    );

    testWidgets(
      '20. scheduled arrival and departure semantics communicate scheduled nature',
      (tester) async {
        final timetable = createTripDetailsTestTimetable();
        final fakeRepo = FakeTripDetailsTimetableRepository(
          timetable: timetable,
        );

        await pumpTripDetailsTest(
          tester,
          child: TripDetailsScreen(tripId: TripId('trip_1')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(
            RegExp(r'scheduled departure\s+8:05\s*AM', caseSensitive: false),
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            RegExp(r'scheduled arrival\s+8:30\s*AM', caseSensitive: false),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('21. prohibited realtime/status wording is completely absent', (
      tester,
    ) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      final prohibited = [
        r'\blive\b',
        r'\bon time\b',
        r'\bdelayed\b',
        r'\bnow at\b',
        r'\barriving now\b',
        r'\beta\b',
        r'\bcurrent stop\b',
        r'\bdeparted\b',
        r'\bvehicle position\b',
      ];

      for (final pattern in prohibited) {
        expect(
          find.textContaining(RegExp(pattern, caseSensitive: false)),
          findsNothing,
          reason: 'Prohibited realtime word found: $pattern',
        );
      }
    });

    testWidgets('22. 200% text scale at 360dp width renders without overflow', (
      tester,
    ) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        surfaceSize: const Size(360, 640),
        textScaleFactor: 2.0,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Route 101'), findsOneWidget);
      expect(find.text('City Center'), findsOneWidget);
    });

    testWidgets('23. light theme renders cleanly', (tester) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        themeMode: ThemeMode.light,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip details'), findsOneWidget);
      expect(find.text('Route 101'), findsOneWidget);
    });

    testWidgets('24. dark theme renders cleanly', (tester) async {
      final timetable = createTripDetailsTestTimetable();
      final fakeRepo = FakeTripDetailsTimetableRepository(timetable: timetable);

      await pumpTripDetailsTest(
        tester,
        themeMode: ThemeMode.dark,
        child: TripDetailsScreen(tripId: TripId('trip_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Trip details'), findsOneWidget);
      expect(find.text('Route 101'), findsOneWidget);
    });
  });
}
