import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/features/browse/presentation/route_details_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_sample_data_notice.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_scheduled_times_note.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

import '../browse_test_support.dart';

Timetable _createMultiVariantTimetable({bool isSampleData = true}) {
  final stops = [
    TransitStop(
      id: StopId('stop_1'),
      name: LocalizedText(english: 'City Center'),
    ),
    TransitStop(
      id: StopId('stop_2'),
      name: LocalizedText(english: 'Midtown Station'),
    ),
    TransitStop(
      id: StopId('stop_3'),
      name: LocalizedText(english: 'North End'),
    ),
  ];

  final routes = [
    TransitRoute(
      id: RouteId('route_multi'),
      shortName: LocalizedText(english: '501'),
      longName: LocalizedText(english: 'City Center - North End Express'),
    ),
    TransitRoute(
      id: RouteId('route_empty'),
      shortName: LocalizedText(english: '502'),
      longName: LocalizedText(english: 'Empty Service Line'),
    ),
  ];

  final trips = [
    // Variant 1: stop_1 -> stop_2 -> stop_3
    ScheduledTrip(
      id: TripId('trip_v1_early'),
      routeId: RouteId('route_multi'),
      serviceDays: const ServiceDays(
        monday: true,
        tuesday: true,
        wednesday: true,
        thursday: true,
        friday: true,
        saturday: true,
        sunday: true,
      ),
      stopTimes: [
        StopTime(
          stopId: StopId('stop_1'),
          arrivalTime: ServiceTime(hour: 6, minute: 0),
          departureTime: ServiceTime(hour: 6, minute: 5),
        ),
        StopTime(
          stopId: StopId('stop_2'),
          arrivalTime: ServiceTime(hour: 6, minute: 20),
          departureTime: ServiceTime(hour: 6, minute: 25),
        ),
        StopTime(
          stopId: StopId('stop_3'),
          arrivalTime: ServiceTime(hour: 6, minute: 45),
          departureTime: ServiceTime(hour: 6, minute: 45),
        ),
      ],
    ),
    // Variant 1 late trip: departure < 24 (23:50), arrival >= 24 (24:20)
    ScheduledTrip(
      id: TripId('trip_v1_late'),
      routeId: RouteId('route_multi'),
      serviceDays: const ServiceDays(
        monday: true,
        wednesday: true,
        friday: true,
      ),
      stopTimes: [
        StopTime(
          stopId: StopId('stop_1'),
          arrivalTime: ServiceTime(hour: 23, minute: 50),
          departureTime: ServiceTime(hour: 23, minute: 50),
        ),
        StopTime(
          stopId: StopId('stop_2'),
          arrivalTime: ServiceTime(hour: 24, minute: 5),
          departureTime: ServiceTime(hour: 24, minute: 5),
        ),
        StopTime(
          stopId: StopId('stop_3'),
          arrivalTime: ServiceTime(hour: 24, minute: 20),
          departureTime: ServiceTime(hour: 24, minute: 20),
        ),
      ],
    ),
    // Variant 1 all-late trip: departure >= 24 (24:30), arrival >= 24 (25:00)
    ScheduledTrip(
      id: TripId('trip_v1_both_late'),
      routeId: RouteId('route_multi'),
      serviceDays: const ServiceDays(saturday: true, sunday: true),
      stopTimes: [
        StopTime(
          stopId: StopId('stop_1'),
          arrivalTime: ServiceTime(hour: 24, minute: 30),
          departureTime: ServiceTime(hour: 24, minute: 30),
        ),
        StopTime(
          stopId: StopId('stop_2'),
          arrivalTime: ServiceTime(hour: 24, minute: 45),
          departureTime: ServiceTime(hour: 24, minute: 45),
        ),
        StopTime(
          stopId: StopId('stop_3'),
          arrivalTime: ServiceTime(hour: 25, minute: 0),
          departureTime: ServiceTime(hour: 25, minute: 0),
        ),
      ],
    ),
    // Variant 2 (reverse): stop_3 -> stop_2 -> stop_1
    ScheduledTrip(
      id: TripId('trip_v2_return'),
      routeId: RouteId('route_multi'),
      serviceDays: const ServiceDays(monday: true, tuesday: true),
      stopTimes: [
        StopTime(
          stopId: StopId('stop_3'),
          arrivalTime: ServiceTime(hour: 7, minute: 0),
          departureTime: ServiceTime(hour: 7, minute: 5),
        ),
        StopTime(
          stopId: StopId('stop_2'),
          arrivalTime: ServiceTime(hour: 7, minute: 20),
          departureTime: ServiceTime(hour: 7, minute: 25),
        ),
        StopTime(
          stopId: StopId('stop_1'),
          arrivalTime: ServiceTime(hour: 7, minute: 45),
          departureTime: ServiceTime(hour: 7, minute: 45),
        ),
      ],
    ),
  ];

  return Timetable(
    info: TimetableInfo(datasetVersion: '1.0.0', isSampleData: isSampleData),
    stops: stops,
    routes: routes,
    trips: trips,
  );
}

void main() {
  group('RouteDetailsScreen (P3.5)', () {
    testWidgets('12. loading renders GtLoadingView', (tester) async {
      final completer = Completer<Timetable>();
      final fakeRepo = FakeBrowseTimetableRepository(completer: completer);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      expect(find.byType(GtLoadingView), findsOneWidget);
    });

    testWidgets('13. error renders GtErrorView', (tester) async {
      final fakeRepo = FakeBrowseTimetableRepository(
        error: const DataFormatFailure(),
      );

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtErrorView), findsOneWidget);
      expect(
        find.text('The timetable data could not be loaded.'),
        findsOneWidget,
      );
    });

    testWidgets('14. retry path re-fetches timetable', (tester) async {
      final fakeRepo = FakeBrowseTimetableRepository(
        error: const DataFormatFailure(),
      );

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtErrorView), findsOneWidget);
      expect(fakeRepo.loadCount, equals(1));

      // Resolve error
      fakeRepo.error = null;
      fakeRepo.timetable = createBrowseTestTimetable();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(fakeRepo.loadCount, equals(2));
      expect(find.byType(GtErrorView), findsNothing);
      expect(find.text('101'), findsOneWidget);
    });

    testWidgets('15. unknown route -> explicit not-found', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
      var backPressed = false;

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(
          routeId: RouteId('route_nonexistent'),
          onBack: () => backPressed = true,
        ),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtEmptyState), findsOneWidget);
      expect(find.text('Route not found'), findsOneWidget);
      expect(
        find.text("This route isn't in the current timetable."),
        findsOneWidget,
      );

      await tester.tap(find.text('Go back'));
      expect(backPressed, isTrue);
    });

    testWidgets('16. unknown route does not render variant/scheduled content', (
      tester,
    ) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_nonexistent')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Stops'), findsNothing);
      expect(find.text('Scheduled trips'), findsNothing);
      expect(find.byType(BrowseScheduledTimesNote), findsNothing);
    });

    testWidgets('17. canonical route header displayed', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('101'), findsOneWidget);
      expect(find.text('City Center - North Station'), findsOneWidget);
    });

    testWidgets('18. sample notice conditional', (tester) async {
      final sampleTimetable = createBrowseTestTimetable(isSampleData: true);
      final fakeRepoSample = FakeBrowseTimetableRepository(
        timetable: sampleTimetable,
      );

      // Sample data shows notice
      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_1')),
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepoSample),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseSampleDataNotice), findsOneWidget);

      // Non-sample data does not show notice
      final realTimetable = createBrowseTestTimetable(isSampleData: false);
      final fakeRepoReal = FakeBrowseTimetableRepository(
        timetable: realTimetable,
      );

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_1')),
        overrides: [
          timetableRepositoryProvider.overrideWithValue(fakeRepoReal),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseSampleDataNotice), findsNothing);
    });

    testWidgets('19. variant order preserved', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Variant 1: City Center to North End
      // Variant 2: North End to City Center
      expect(find.text('Variant 1: City Center to North End'), findsOneWidget);
      expect(find.text('Variant 2: North End to City Center'), findsOneWidget);

      final variantTexts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data)
          .where(
            (text) =>
                text == 'Variant 1: City Center to North End' ||
                text == 'Variant 2: North End to City Center',
          )
          .toList();

      expect(
        variantTexts,
        equals([
          'Variant 1: City Center to North End',
          'Variant 2: North End to City Center',
        ]),
      );
    });

    testWidgets(
      '20. reverse/different stop-pattern variants remain separate as supplied',
      (tester) async {
        final timetable = _createMultiVariantTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

        await pumpBrowseTest(
          tester,
          child: RouteDetailsScreen(routeId: RouteId('route_multi')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // 2 distinct variant sections
        expect(
          find.text('Variant 1: City Center to North End'),
          findsOneWidget,
        );
        expect(
          find.text('Variant 2: North End to City Center'),
          findsOneWidget,
        );
      },
    );

    testWidgets('21. full ordered stop sequence rendered', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // All stops in variant 1 are rendered
      expect(find.text('City Center'), findsAtLeastNWidgets(1));
      expect(find.text('Midtown Station'), findsAtLeastNWidgets(1));
      expect(find.text('North End'), findsAtLeastNWidgets(1));
    });

    testWidgets('22. intermediate stops rendered', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Midtown Station is intermediate in both variants
      expect(find.text('Midtown Station'), findsNWidgets(2));
    });

    testWidgets('23. variant trip order preserved', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Variant 1 has 3 trips sorted chronologically: 6:05 AM, 11:50 PM, 12:30 AM
      expect(find.text('6:05 AM'), findsOneWidget);
      expect(find.text('11:50 PM'), findsOneWidget);
      expect(find.text('12:30 AM'), findsOneWidget);
    });

    testWidgets('24. first departure displayed', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // First trip first stop departure is 6:05 AM
      expect(find.text('6:05 AM'), findsOneWidget);
    });

    testWidgets('25. final arrival displayed', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // First trip last stop arrival is 6:45 AM
      expect(find.text('6:45 AM'), findsOneWidget);
    });

    testWidgets('26. running days displayed', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // First trip runs everyday
      expect(find.text('Runs every day'), findsOneWidget);
      // Second trip runs Mon, Wed, Fri
      expect(find.text('Runs Mon, Wed, Fri'), findsOneWidget);
      // Third trip runs Sat, Sun
      expect(find.text('Runs Sat, Sun'), findsOneWidget);
      // Reverse trip runs Mon, Tue
      expect(find.text('Runs Mon, Tue'), findsOneWidget);
    });

    testWidgets('27. departure >=24 receives +1', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Trip with dep 24:30 and arr 25:00: departure 24:30 normalized to 12:30 AM has +1
      expect(find.text('12:30 AM'), findsOneWidget);
      expect(find.text('+1'), findsAtLeastNWidgets(1));
    });

    testWidgets('28. arrival >=24 receives +1', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Trip with dep 23:50 and arr 24:20: arrival 24:20 normalized to 12:20 AM has +1
      expect(find.text('12:20 AM'), findsOneWidget);
      expect(find.text('+1'), findsAtLeastNWidgets(1));
    });

    testWidgets('29. both endpoints >=24 each receive +1', (tester) async {
      // Create a isolated timetable with exactly ONE trip that has both endpoints >= 24
      final tripBothLate = ScheduledTrip(
        id: TripId('trip_both_late'),
        routeId: RouteId('route_late'),
        serviceDays: const ServiceDays(monday: true),
        stopTimes: [
          StopTime(
            stopId: StopId('stop_1'),
            arrivalTime: ServiceTime(hour: 24, minute: 10),
            departureTime: ServiceTime(hour: 24, minute: 10),
          ),
          StopTime(
            stopId: StopId('stop_2'),
            arrivalTime: ServiceTime(hour: 24, minute: 40),
            departureTime: ServiceTime(hour: 24, minute: 40),
          ),
        ],
      );

      final timetable = Timetable(
        info: TimetableInfo(datasetVersion: '1.0.0', isSampleData: false),
        stops: [
          TransitStop(
            id: StopId('stop_1'),
            name: LocalizedText(english: 'Stop A'),
          ),
          TransitStop(
            id: StopId('stop_2'),
            name: LocalizedText(english: 'Stop B'),
          ),
        ],
        routes: [
          TransitRoute(
            id: RouteId('route_late'),
            shortName: LocalizedText(english: 'L1'),
            longName: LocalizedText(english: 'Late Route'),
          ),
        ],
        trips: [tripBothLate],
      );

      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_late')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // 12:10 AM +1 and 12:40 AM +1 -> exactly 2 "+1" markers!
      expect(find.text('12:10 AM'), findsOneWidget);
      expect(find.text('12:40 AM'), findsOneWidget);
      expect(find.text('+1'), findsNWidgets(2));
    });

    testWidgets('30. <24 endpoint does not receive +1', (tester) async {
      final tripDay = ScheduledTrip(
        id: TripId('trip_day'),
        routeId: RouteId('route_day'),
        serviceDays: const ServiceDays(monday: true),
        stopTimes: [
          StopTime(
            stopId: StopId('stop_1'),
            arrivalTime: ServiceTime(hour: 10, minute: 0),
            departureTime: ServiceTime(hour: 10, minute: 5),
          ),
          StopTime(
            stopId: StopId('stop_2'),
            arrivalTime: ServiceTime(hour: 10, minute: 30),
            departureTime: ServiceTime(hour: 10, minute: 35),
          ),
        ],
      );

      final timetable = Timetable(
        info: TimetableInfo(datasetVersion: '1.0.0', isSampleData: false),
        stops: [
          TransitStop(
            id: StopId('stop_1'),
            name: LocalizedText(english: 'Stop A'),
          ),
          TransitStop(
            id: StopId('stop_2'),
            name: LocalizedText(english: 'Stop B'),
          ),
        ],
        routes: [
          TransitRoute(
            id: RouteId('route_day'),
            shortName: LocalizedText(english: 'D1'),
            longName: LocalizedText(english: 'Day Route'),
          ),
        ],
        trips: [tripDay],
      );

      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_day')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // No +1 markers anywhere
      expect(find.text('+1'), findsNothing);
    });

    testWidgets('31. accessibility semantics communicate next day', (
      tester,
    ) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('next day', caseSensitive: false)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets(
      '31a. departure endpoint exposes "Departs ..." semantics and arrival endpoint exposes "Arrives ..." semantics',
      (tester) async {
        final timetable = _createMultiVariantTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

        await pumpBrowseTest(
          tester,
          child: RouteDetailsScreen(routeId: RouteId('route_multi')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(
            RegExp(r'Departs\s+6:05\s*AM', caseSensitive: false),
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            RegExp(r'Arrives\s+6:45\s*AM', caseSensitive: false),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '31b. next-day departure and arrival semantics communicate both endpoint type and "next day"',
      (tester) async {
        final timetable = _createMultiVariantTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

        await pumpBrowseTest(
          tester,
          child: RouteDetailsScreen(routeId: RouteId('route_multi')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(
          find.bySemanticsLabel(
            RegExp(r'Departs\s+12:30\s*AM\s+next day', caseSensitive: false),
          ),
          findsOneWidget,
        );
        expect(
          find.bySemanticsLabel(
            RegExp(r'Arrives\s+12:20\s*AM\s+next day', caseSensitive: false),
          ),
          findsOneWidget,
        );

        // Visible +1 markers still present
        expect(find.text('+1'), findsAtLeastNWidgets(1));
      },
    );

    testWidgets('32. zero-variant known route is NOT not-found', (
      tester,
    ) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_empty')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtEmptyState), findsNothing);
      expect(find.text('Route not found'), findsNothing);
      expect(find.text('502'), findsOneWidget);
      expect(find.text('Empty Service Line'), findsOneWidget);
    });

    testWidgets(
      '33. zero-variant route shows explicit no-scheduled-service state',
      (tester) async {
        final timetable = _createMultiVariantTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

        await pumpBrowseTest(
          tester,
          child: RouteDetailsScreen(routeId: RouteId('route_empty')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(
          find.text('No scheduled trips available for this route.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '34. zero-variant route does NOT show scheduled-times disclosure',
      (tester) async {
        final timetable = _createMultiVariantTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

        await pumpBrowseTest(
          tester,
          child: RouteDetailsScreen(routeId: RouteId('route_empty')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.byType(BrowseScheduledTimesNote), findsNothing);
      },
    );

    testWidgets(
      '35. route with variants DOES show scheduled-times disclosure',
      (tester) async {
        final timetable = _createMultiVariantTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

        await pumpBrowseTest(
          tester,
          child: RouteDetailsScreen(routeId: RouteId('route_multi')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.byType(BrowseScheduledTimesNote), findsOneWidget);
        expect(
          find.text('Scheduled times. Actual times may vary.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('36. no live/ETA/realtime/punctuality wording', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      final allTexts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data?.toLowerCase() ?? '')
          .toList();

      for (final text in allTexts) {
        expect(
          RegExp(r'\blive\b').hasMatch(text),
          isFalse,
          reason: 'Found "live" in $text',
        );
        expect(
          RegExp(r'\beta\b').hasMatch(text),
          isFalse,
          reason: 'Found "eta" in $text',
        );
        expect(
          text.contains('realtime'),
          isFalse,
          reason: 'Found "realtime" in $text',
        );
        expect(
          text.contains('real-time'),
          isFalse,
          reason: 'Found "real-time" in $text',
        );
        expect(
          text.contains('delayed'),
          isFalse,
          reason: 'Found "delayed" in $text',
        );
        expect(
          text.contains('on time'),
          isFalse,
          reason: 'Found "on time" in $text',
        );
      }
    });

    testWidgets(
      '37. trip callback receives correct TripId if trip interaction exists',
      (tester) async {
        final timetable = _createMultiVariantTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
        TripId? tappedTripId;

        await pumpBrowseTest(
          tester,
          child: RouteDetailsScreen(
            routeId: RouteId('route_multi'),
            onTripTap: (id) => tappedTripId = id,
          ),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Tap the first trip row
        await tester.tap(find.text('6:05 AM'));
        expect(tappedTripId, equals(TripId('trip_v1_early')));
      },
    );

    testWidgets('38. callback-null state does not navigate/crash', (
      tester,
    ) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(
          routeId: RouteId('route_multi'),
          onTripTap: null,
        ),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('6:05 AM'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('39. 360dp / 200% text no overflow', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        surfaceSize: const Size(360, 640),
        textScaleFactor: 2.0,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('501'), findsOneWidget);
    });

    testWidgets('40. light/dark smoke', (tester) async {
      final timetable = _createMultiVariantTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      // Light theme
      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        themeMode: ThemeMode.light,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();
      expect(find.text('501'), findsOneWidget);

      // Dark theme
      await pumpBrowseTest(
        tester,
        child: RouteDetailsScreen(routeId: RouteId('route_multi')),
        themeMode: ThemeMode.dark,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();
      expect(find.text('501'), findsOneWidget);
    });
  });
}
