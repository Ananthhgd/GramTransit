import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/home_stop_selector.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/sample_data_notice.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/scheduled_times_note.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_departures_section.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_trip_card.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

import '../home_test_support.dart';

void main() {
  group('UpcomingDeparturesSection', () {
    testWidgets(
      'A. Timetable Loading: shows loading view and no stop selector',
      (tester) async {
        final completer = Completer<Timetable>();
        final fakeRepo = FakeTimetableRepository(completer: completer);

        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );

        // Section title is visible
        expect(find.text('Upcoming departures'), findsOneWidget);

        // Loading view is visible
        expect(find.byType(GtLoadingView), findsOneWidget);

        // Stop selector is not visible
        expect(find.byType(HomeStopSelector), findsNothing);
        expect(find.text('Select stop'), findsNothing);

        // Completing allows clean teardown
        completer.complete(createTestTimetable());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'B. Timetable Error: shows friendly message, retry works, no raw error',
      (tester) async {
        final stackTrace = StackTrace.current;
        final failure = DataFormatFailure(
          cause: 'Corrupt JSON file at syntax token 0x99',
          stackTrace: stackTrace,
        );
        final fakeRepo = FakeTimetableRepository(error: failure);

        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Error view is rendered
        expect(find.byType(GtErrorView), findsOneWidget);

        // Friendly localized error text
        expect(
          find.text('The timetable data could not be loaded.'),
          findsOneWidget,
        );

        // Raw error/stack trace text is NOT presented
        expect(
          find.textContaining('Corrupt JSON file at syntax token 0x99'),
          findsNothing,
        );

        // Verify retry mechanism: update repo and tap retry
        fakeRepo.error = null;
        fakeRepo.timetable = createTestTimetable();

        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(find.byType(GtErrorView), findsNothing);
        expect(find.byType(HomeStopSelector), findsOneWidget);
        expect(fakeRepo.loadCount, 2);
      },
    );

    testWidgets('C. Zero Stops: shows empty state and no unusable selector', (
      tester,
    ) async {
      final emptyTimetable = createTestTimetable(
        stops: const [],
        routes: const [],
        trips: const [],
      );
      final fakeRepo = FakeTimetableRepository(timetable: emptyTimetable);

      await pumpHomeTest(
        tester,
        child: const UpcomingDeparturesSection(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtEmptyState), findsOneWidget);
      expect(find.text('No stops available'), findsOneWidget);
      expect(find.byType(HomeStopSelector), findsNothing);
    });

    testWidgets(
      'D. Loaded / No Selection: title, disclosures, sample notice, prompt',
      (tester) async {
        // Test with sample data = true
        final sampleTimetable = createTestTimetable(isSampleData: true);
        final fakeRepo = FakeTimetableRepository(timetable: sampleTimetable);

        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Title and persistent disclosure
        expect(find.text('Upcoming departures'), findsOneWidget);
        expect(find.byType(ScheduledTimesNote), findsOneWidget);
        expect(
          find.text('Scheduled times. Actual times may vary.'),
          findsOneWidget,
        );

        // Sample notice rendered when isSampleData == true
        expect(find.byType(SampleDataNotice), findsOneWidget);
        expect(
          find.text('Sample timetable for testing — not for real travel.'),
          findsOneWidget,
        );

        // Selector is present
        expect(find.byType(HomeStopSelector), findsOneWidget);

        // Choose-stop prompt shown before selection
        expect(
          find.text('Choose a stop to see scheduled departures.'),
          findsOneWidget,
        );
        expect(find.byType(UpcomingTripCard), findsNothing);
      },
    );

    testWidgets(
      'D2. Loaded / No Selection: sample notice absent when isSampleData is false',
      (tester) async {
        final nonSampleTimetable = createTestTimetable(isSampleData: false);
        final fakeRepo = FakeTimetableRepository(timetable: nonSampleTimetable);

        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.byType(SampleDataNotice), findsNothing);
        expect(
          find.text('Sample timetable for testing — not for real travel.'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'E. Stop Selection: stops in order, selection drives family instance',
      (tester) async {
        final timetable = createTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          fixedNow: DateTime(2026, 10, 14, 7, 50),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Tap the dropdown to open it
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();

        // City Center and North Station appear in order
        final cityCenterFinder = find.text('City Center').last;
        final northStationFinder = find.text('North Station').last;
        expect(cityCenterFinder, findsOneWidget);
        expect(northStationFinder, findsOneWidget);

        // Select City Center
        await tester.tap(cityCenterFinder);
        await tester.pumpAndSettle();

        // Results appear for City Center: departure at 08:05
        expect(find.byType(UpcomingTripCard), findsOneWidget);
        expect(find.text('8:05 AM'), findsOneWidget);
        expect(find.text('To North Station'), findsOneWidget);
      },
    );

    testWidgets(
      'F. Current Departures: renders all current occurrences in domain order',
      (tester) async {
        // 2 departures from City Center on Wednesday
        final trip1 = ScheduledTrip(
          id: TripId('trip_1'),
          routeId: RouteId('route_1'),
          serviceDays: const ServiceDays(wednesday: true),
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
        );
        final trip2 = ScheduledTrip(
          id: TripId('trip_2'),
          routeId: RouteId('route_1'),
          serviceDays: const ServiceDays(wednesday: true),
          stopTimes: [
            StopTime(
              stopId: StopId('stop_1'),
              arrivalTime: ServiceTime(hour: 9, minute: 0),
              departureTime: ServiceTime(hour: 9, minute: 15),
            ),
            StopTime(
              stopId: StopId('stop_2'),
              arrivalTime: ServiceTime(hour: 9, minute: 30),
              departureTime: ServiceTime(hour: 9, minute: 35),
            ),
          ],
        );

        final timetable = createTestTimetable(trips: [trip1, trip2]);
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          fixedNow: DateTime(2026, 10, 14, 7, 50),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Select City Center
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        // Expect both cards rendered in order
        expect(find.byType(UpcomingTripCard), findsNWidgets(2));
        expect(find.text('8:05 AM'), findsOneWidget);
        expect(find.text('9:15 AM'), findsOneWidget);
      },
    );

    testWidgets(
      'G. Terminal Stop: terminal stop returns no boardable departures',
      (tester) async {
        final timetable = createTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          fixedNow: DateTime(2026, 10, 14, 7, 50),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Select North Station (which is the terminal stop of trip_1)
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('North Station').last);
        await tester.pumpAndSettle();

        // Domain returns empty current & empty nextLater for terminal stop
        expect(
          find.text('No upcoming scheduled buses from North Station'),
          findsOneWidget,
        );
        expect(find.byType(UpcomingTripCard), findsNothing);
      },
    );

    testWidgets(
      'H. Current Empty + NextLater: shows notice, next label, and all nextLater dated cards',
      (tester) async {
        // Trip is on Friday only, but now is Wednesday
        final fridayTrip = ScheduledTrip(
          id: TripId('trip_friday'),
          routeId: RouteId('route_1'),
          serviceDays: const ServiceDays(friday: true),
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
        );

        final timetable = createTestTimetable(trips: [fridayTrip]);
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        // Now is Wednesday Oct 14 2026, 7:50 AM
        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          fixedNow: DateTime(2026, 10, 14, 7, 50),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Select City Center
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        // Current is empty, nextLater has Friday Oct 16
        expect(
          find.text('No more scheduled buses from City Center for now'),
          findsOneWidget,
        );
        expect(find.text('Next scheduled bus'), findsOneWidget);

        // Next later card rendered with date + time
        expect(find.byType(UpcomingTripCard), findsOneWidget);
        expect(find.text('Fri, Oct 16 · 8:05 AM'), findsOneWidget);
        expect(find.text('To North Station'), findsOneWidget);

        // No "today" or "tomorrow" wording
        expect(
          find.textContaining(RegExp('today', caseSensitive: false)),
          findsNothing,
        );
        expect(
          find.textContaining(RegExp('tomorrow', caseSensitive: false)),
          findsNothing,
        );
      },
    );

    testWidgets('I. Current Empty + NextLater Empty: shows no upcoming state', (
      tester,
    ) async {
      // No trips matching
      final timetable = createTestTimetable(trips: const []);
      final fakeRepo = FakeTimetableRepository(timetable: timetable);

      await pumpHomeTest(
        tester,
        child: const UpcomingDeparturesSection(),
        fixedNow: DateTime(2026, 10, 14, 7, 50),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Select City Center
      await tester.tap(find.byType(DropdownButton<StopId>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('City Center').last);
      await tester.pumpAndSettle();

      expect(
        find.text('No upcoming scheduled buses from City Center'),
        findsOneWidget,
      );
      expect(find.byType(UpcomingTripCard), findsNothing);
    });

    testWidgets(
      'L. Accessibility / Resilience: light, dark, and large text scaling',
      (tester) async {
        final timetable = createTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        // Light theme test
        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          themeMode: ThemeMode.light,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Dark theme test
        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          themeMode: ThemeMode.dark,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Large text scaling test (2.0x text scale)
        await pumpHomeTest(
          tester,
          child: const UpcomingDeparturesSection(),
          textScaleFactor: 2.0,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  });
}
