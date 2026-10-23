import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_screen.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/home_explore_section.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/home_header.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/home_stop_selector.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/sample_data_notice.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/scheduled_times_note.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/search_entry_placeholder.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_departures_section.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_trip_card.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

import '../home_test_support.dart';

void main() {
  group('HomeScreen (Model H-A)', () {
    testWidgets('1. Initial state: starts with selectedStopId == null', (
      tester,
    ) async {
      final sampleTimetable = createTestTimetable();
      final fakeRepo = FakeTimetableRepository(timetable: sampleTimetable);

      await pumpHomeTest(
        tester,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Core widgets are rendered
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(HomeHeader), findsOneWidget);
      expect(find.byType(SearchEntryPlaceholder), findsOneWidget);
      expect(find.byType(HomeExploreSection), findsOneWidget);
      expect(find.byType(UpcomingDeparturesSection), findsOneWidget);

      // Controlled UpcomingDeparturesSection starts with selectedStopId == null
      final departuresSection = tester.widget<UpcomingDeparturesSection>(
        find.byType(UpcomingDeparturesSection),
      );
      expect(departuresSection.selectedStopId, isNull);

      // Displays choose stop prompt
      expect(
        find.text('Choose a stop to see scheduled departures.'),
        findsOneWidget,
      );
      expect(find.byType(UpcomingTripCard), findsNothing);
    });

    testWidgets('2. Boarding stop choices remain available in order', (
      tester,
    ) async {
      final timetable = createTestTimetable();
      final fakeRepo = FakeTimetableRepository(timetable: timetable);

      await pumpHomeTest(
        tester,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Open selector dropdown
      await tester.tap(find.byType(DropdownButton<StopId>));
      await tester.pumpAndSettle();

      final cityCenter = find.text('City Center').last;
      final northStation = find.text('North Station').last;
      expect(cityCenter, findsOneWidget);
      expect(northStation, findsOneWidget);
    });

    testWidgets(
      '3 & 4 & 5. Selecting a stop updates HomeScreen state and refreshes upcoming departures',
      (tester) async {
        final timetable = createTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpHomeTest(
          tester,
          fixedNow: DateTime(2026, 10, 14, 7, 50),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Select City Center
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        // HomeScreen now passes selectedStopId == stop_1 to child
        final departuresSection = tester.widget<UpcomingDeparturesSection>(
          find.byType(UpcomingDeparturesSection),
        );
        expect(departuresSection.selectedStopId, equals(StopId('stop_1')));

        // Upcoming departures refresh for stop_1
        expect(find.byType(UpcomingTripCard), findsOneWidget);
        expect(find.text('8:05 AM'), findsOneWidget);
        expect(find.text('To North Station'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Changing stop updates HomeScreen and refreshes visible departures',
      (tester) async {
        final timetable = createTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpHomeTest(
          tester,
          fixedNow: DateTime(2026, 10, 14, 7, 50),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // 1. Select City Center
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        expect(find.byType(UpcomingTripCard), findsOneWidget);
        expect(find.text('8:05 AM'), findsOneWidget);

        // 2. Change to North Station
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('North Station').last);
        await tester.pumpAndSettle();

        final updatedSection = tester.widget<UpcomingDeparturesSection>(
          find.byType(UpcomingDeparturesSection),
        );
        expect(updatedSection.selectedStopId, equals(StopId('stop_2')));

        // North Station is a terminal stop on this trip, so no boardable departures
        expect(
          find.text('No upcoming scheduled buses from North Station'),
          findsOneWidget,
        );
        expect(find.byType(UpcomingTripCard), findsNothing);
      },
    );

    testWidgets(
      '7. Null selection remains safe and does not query upcoming departures',
      (tester) async {
        final timetable = createTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpHomeTest(
          tester,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        final section = tester.widget<UpcomingDeparturesSection>(
          find.byType(UpcomingDeparturesSection),
        );
        expect(section.selectedStopId, isNull);

        expect(
          find.text('Choose a stop to see scheduled departures.'),
          findsOneWidget,
        );
        expect(find.byType(UpcomingTripCard), findsNothing);
      },
    );

    testWidgets('8. Timetable loading state is rendered', (tester) async {
      final completer = Completer<Timetable>();
      final fakeRepo = FakeTimetableRepository(completer: completer);

      await pumpHomeTest(
        tester,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      expect(find.byType(GtLoadingView), findsOneWidget);
      expect(find.byType(HomeStopSelector), findsNothing);

      completer.complete(createTestTimetable());
      await tester.pumpAndSettle();
    });

    testWidgets('9. Timetable error state is rendered with retry', (
      tester,
    ) async {
      final failure = DataFormatFailure(
        cause: 'Corrupt JSON',
        stackTrace: StackTrace.current,
      );
      final fakeRepo = FakeTimetableRepository(error: failure);

      await pumpHomeTest(
        tester,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtErrorView), findsOneWidget);
      expect(
        find.text('The timetable data could not be loaded.'),
        findsOneWidget,
      );

      fakeRepo.error = null;
      fakeRepo.timetable = createTestTimetable();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(GtErrorView), findsNothing);
      expect(find.byType(HomeStopSelector), findsOneWidget);
    });

    testWidgets(
      '10 & 11. Disclosures: sample-data notice and scheduled-times disclaimer',
      (tester) async {
        final sampleTimetable = createTestTimetable(isSampleData: true);
        final fakeRepo = FakeTimetableRepository(timetable: sampleTimetable);

        await pumpHomeTest(
          tester,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.byType(ScheduledTimesNote), findsOneWidget);
        expect(
          find.text('Scheduled times. Actual times may vary.'),
          findsOneWidget,
        );

        expect(find.byType(SampleDataNotice), findsOneWidget);
        expect(
          find.text('Sample timetable for testing — not for real travel.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '13. SearchEntryPlaceholder triggers search navigation callback with selected stop in P2.6',
      (tester) async {
        final timetable = createTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);
        StopId? searchedStopId;
        var searchTapped = false;

        await pumpHomeTest(
          tester,
          onSearchTap: (stopId) {
            searchTapped = true;
            searchedStopId = stopId;
          },
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.byType(SearchEntryPlaceholder), findsOneWidget);
        expect(find.text('Where are you going?'), findsOneWidget);

        // Tap the placeholder with no stop selected
        await tester.tap(find.byType(SearchEntryPlaceholder));
        await tester.pumpAndSettle();

        expect(searchTapped, isTrue);
        expect(searchedStopId, isNull);

        // Select a stop and tap again
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        searchTapped = false;
        await tester.tap(find.byType(SearchEntryPlaceholder));
        await tester.pumpAndSettle();

        expect(searchTapped, isTrue);
        expect(searchedStopId, StopId('stop_1'));
      },
    );

    testWidgets(
      '14. Home Explore Section: appears between SearchEntryPlaceholder and UpcomingDeparturesSection and triggers navigation callbacks without mutating selectedStopId',
      (tester) async {
        final timetable = createTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);
        var allStopsTapped = false;
        var allRoutesTapped = false;

        await pumpHomeTest(
          tester,
          onAllStopsTap: () => allStopsTapped = true,
          onAllRoutesTap: () => allRoutesTapped = true,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // 1. Placement verification: SearchEntryPlaceholder -> HomeExploreSection -> UpcomingDeparturesSection
        final searchY = tester
            .getTopLeft(find.byType(SearchEntryPlaceholder))
            .dy;
        final exploreY = tester.getTopLeft(find.byType(HomeExploreSection)).dy;
        final departuresY = tester
            .getTopLeft(find.byType(UpcomingDeparturesSection))
            .dy;

        expect(searchY, lessThan(exploreY));
        expect(exploreY, lessThan(departuresY));

        // 2. Explore content rendered
        expect(find.text('Explore'), findsOneWidget);
        expect(find.text('All stops'), findsOneWidget);
        expect(find.text('All routes'), findsOneWidget);

        // 3. Tap All stops invokes callback
        await tester.tap(find.text('All stops'));
        await tester.pumpAndSettle();
        expect(allStopsTapped, isTrue);

        // 4. Tap All routes invokes callback
        await tester.tap(find.text('All routes'));
        await tester.pumpAndSettle();
        expect(allRoutesTapped, isTrue);

        // 5. selectedStopId remains null
        final departuresSection = tester.widget<UpcomingDeparturesSection>(
          find.byType(UpcomingDeparturesSection),
        );
        expect(departuresSection.selectedStopId, isNull);

        // 6. Select a stop -> selectedStopId updates -> tapping Explore does not mutate selectedStopId
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        final updatedSection = tester.widget<UpcomingDeparturesSection>(
          find.byType(UpcomingDeparturesSection),
        );
        expect(updatedSection.selectedStopId, equals(StopId('stop_1')));

        await tester.tap(find.text('All stops'));
        await tester.pumpAndSettle();

        final afterTapSection = tester.widget<UpcomingDeparturesSection>(
          find.byType(UpcomingDeparturesSection),
        );
        expect(afterTapSection.selectedStopId, equals(StopId('stop_1')));
      },
    );
  });
}
