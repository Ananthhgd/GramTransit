import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/journey_search_screen.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/journey_results_section.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/journey_sample_data_notice.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/journey_scheduled_times_note.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/journey_stop_selector.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/scheduled_journey_card.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/scheduled_journey.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

import '../journey_search_test_support.dart';

Finder findFromSearchBar() => find.byType(SearchBar).first;
Finder findToSearchBar() => find.byType(SearchBar).last;

void main() {
  group('JourneySearchScreen (P2.5)', () {
    testWidgets(
      'A. Initial state: null From and null To show guidance, no journey query active',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpJourneySearchTest(
          tester,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Screen and core components render
        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.byType(JourneyStopSelector), findsNWidgets(2));
        expect(find.byType(JourneyResultsSection), findsOneWidget);

        // Disclosures present
        expect(find.byType(JourneyScheduledTimesNote), findsOneWidget);
        expect(find.byType(JourneySampleDataNotice), findsOneWidget);
        expect(
          find.text('Scheduled times. Actual times may vary.'),
          findsOneWidget,
        );
        expect(
          find.text('Sample timetable for testing — not for real travel.'),
          findsOneWidget,
        );

        // Placeholders visible
        expect(find.text('Choose starting stop'), findsOneWidget);
        expect(find.text('Choose destination stop'), findsOneWidget);

        // Guidance prompt shown
        expect(
          find.text(
            'Select a starting stop and destination to view scheduled journeys.',
          ),
          findsOneWidget,
        );

        // No results or journey cards
        expect(find.byType(ScheduledJourneyCard), findsNothing);
      },
    );

    testWidgets(
      'B. Initial boarding stop: valid initialBoardingStopId displays stop and To excludes it',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpJourneySearchTest(
          tester,
          initialBoardingStopId: StopId('stop_alpha_1'),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // From selector displays the resolved stop name
        expect(
          find.descendant(
            of: findFromSearchBar(),
            matching: find.text('Alpha Central'),
          ),
          findsOneWidget,
        );
        expect(find.text('Choose destination stop'), findsOneWidget);

        // Open To search
        await tester.tap(findToSearchBar());
        await tester.pumpAndSettle();

        // Suggestions in To must exclude stop_alpha_1
        // We have stop_alpha_2 (duplicate name), Beta Junction, Central Station.
        // There should only be ONE Alpha Central in suggestions (stop_alpha_2), not two.
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_alpha_1')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_alpha_2')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_beta')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_central')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'B2. Invalid initial boarding stop: non-fatal, handled gracefully as unselected',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpJourneySearchTest(
          tester,
          initialBoardingStopId: StopId('non_existent_stop'),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Does not throw, From displays placeholder
        expect(find.text('Choose starting stop'), findsOneWidget);
        expect(find.text('Choose destination stop'), findsOneWidget);
        expect(
          find.text(
            'Select a starting stop and destination to view scheduled journeys.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'C. From search: empty query ordering, search ranking, duplicate name selection by StopId',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpJourneySearchTest(
          tester,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Open From search
        await tester.tap(findFromSearchBar());
        await tester.pumpAndSettle();

        // Empty query lists all candidate stops in timetable order
        // In createJourneyTestTimetable: stop_alpha_1, stop_alpha_2, stop_beta, stop_central
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_alpha_1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_alpha_2')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_beta')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_central')),
          findsOneWidget,
        );

        // Duplicate names exist for stop_alpha_1 and stop_alpha_2
        // Tap specifically the second duplicate stop (stop_alpha_2)
        await tester.tap(
          find.byKey(const ValueKey('stop_suggestion_stop_alpha_2')),
        );
        await tester.pumpAndSettle();

        // From selector is updated
        expect(
          find.descendant(
            of: findFromSearchBar(),
            matching: find.text('Alpha Central'),
          ),
          findsOneWidget,
        );

        // Check To selector now excludes stop_alpha_2
        await tester.tap(findToSearchBar());
        await tester.pumpAndSettle();

        // In To suggestions, stop_alpha_1 remains available while stop_alpha_2 is excluded
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_alpha_1')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_alpha_2')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'D. To search: excludes From and cannot become same StopId as From',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpJourneySearchTest(
          tester,
          initialBoardingStopId: StopId('stop_beta'),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Open To search
        await tester.tap(findToSearchBar());
        await tester.pumpAndSettle();

        // stop_beta is excluded
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_beta')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('stop_suggestion_stop_central')),
          findsOneWidget,
        );

        // Select Central Station
        await tester.tap(
          find.byKey(const ValueKey('stop_suggestion_stop_central')),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: findToSearchBar(),
            matching: find.text('Central Station'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('E. Changing From: if new From == current To, To clears', (
      tester,
    ) async {
      final timetable = createJourneyTestTimetable();
      final fakeRepo = FakeTimetableRepository(timetable: timetable);

      await pumpJourneySearchTest(
        tester,
        initialBoardingStopId: StopId('stop_alpha_1'),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Select Central Station as To
      await tester.tap(findToSearchBar());
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('stop_suggestion_stop_central')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: findToSearchBar(),
          matching: find.text('Central Station'),
        ),
        findsOneWidget,
      );

      // Now change From to Central Station
      await tester.tap(findFromSearchBar());
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('stop_suggestion_stop_central')),
      );
      await tester.pumpAndSettle();

      // From is now Central Station, and To must be cleared
      expect(
        find.descendant(
          of: findFromSearchBar(),
          matching: find.text('Central Station'),
        ),
        findsOneWidget,
      );
      expect(find.text('Choose destination stop'), findsOneWidget);
    });

    testWidgets('F. Swap: verifies all 4 swap states', (tester) async {
      final timetable = createJourneyTestTimetable();
      final fakeRepo = FakeTimetableRepository(timetable: timetable);

      await pumpJourneySearchTest(
        tester,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      final swapButton = find.byTooltip('Swap stops');
      expect(swapButton, findsOneWidget);

      // State 4: Neither selected -> no-op
      await tester.tap(swapButton);
      await tester.pumpAndSettle();
      expect(find.text('Choose starting stop'), findsOneWidget);
      expect(find.text('Choose destination stop'), findsOneWidget);

      // Select From = Alpha Central (stop_alpha_1)
      await tester.tap(findFromSearchBar());
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('stop_suggestion_stop_alpha_1')),
      );
      await tester.pumpAndSettle();

      // State 2: Only From selected -> To becomes previous From, From becomes null
      await tester.tap(swapButton);
      await tester.pumpAndSettle();
      expect(find.text('Choose starting stop'), findsOneWidget);
      expect(
        find.descendant(
          of: findToSearchBar(),
          matching: find.text('Alpha Central'),
        ),
        findsOneWidget,
      );

      // State 3: Only To selected -> From becomes previous To, To becomes null
      await tester.tap(swapButton);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: findFromSearchBar(),
          matching: find.text('Alpha Central'),
        ),
        findsOneWidget,
      );
      expect(find.text('Choose destination stop'), findsOneWidget);

      // Now select To = Central Station (State 1: Both selected)
      await tester.tap(findToSearchBar());
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('stop_suggestion_stop_central')),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: findFromSearchBar(),
          matching: find.text('Alpha Central'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: findToSearchBar(),
          matching: find.text('Central Station'),
        ),
        findsOneWidget,
      );

      // Tap Swap: From becomes Central Station, To becomes Alpha Central
      await tester.tap(swapButton);
      await tester.pumpAndSettle();

      // Central Station is in From, Alpha Central is in To
      expect(
        find.descendant(
          of: findFromSearchBar(),
          matching: find.text('Central Station'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: findToSearchBar(),
          matching: find.text('Alpha Central'),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'G & H. Journey provider activation and Results rendering: route identity, scheduled times, duration, stops context',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);
        ScheduledJourney? selectedJourney;

        await pumpJourneySearchTest(
          tester,
          fixedNow: DateTime(2026, 1, 5, 7, 30), // Before 8:00
          initialBoardingStopId: StopId('stop_alpha_1'),
          onJourneySelected: (j) => selectedJourney = j,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Select destination = Central Station
        await tester.tap(findToSearchBar());
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('stop_suggestion_stop_central')),
        );
        await tester.pumpAndSettle();

        // ScheduledJourneyCard appears
        expect(find.byType(ScheduledJourneyCard), findsWidgets);

        // Route identity & context
        expect(find.text('Route 101 · To Central Station'), findsWidgets);

        // Departure and arrival
        expect(find.text('8:00 AM'), findsOneWidget);
        expect(find.text('8:30 AM'), findsOneWidget);

        // Duration (30 min)
        expect(find.text('30 min'), findsWidgets);

        // Stops context
        expect(find.text('Alpha Central → Central Station'), findsWidgets);

        // Tapping card invokes callback
        await tester.tap(find.text('8:00 AM'));
        await tester.pumpAndSettle();
        expect(selectedJourney, isNotNull);
        expect(selectedJourney!.tripId, equals(TripId('trip_morning')));
      },
    );

    testWidgets(
      'I. Zero-duration journey: displays "Less than 1 min" and journey remains visible',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpJourneySearchTest(
          tester,
          fixedNow: DateTime(2026, 1, 5, 7, 30),
          initialBoardingStopId: StopId('stop_alpha_1'),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Select Beta Junction (trip_zero_duration runs from stop_alpha_1 to stop_beta 9:00 -> 9:00)
        await tester.tap(findToSearchBar());
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('stop_suggestion_stop_beta')),
        );
        await tester.pumpAndSettle();

        // Card is displayed
        expect(find.byType(ScheduledJourneyCard), findsOneWidget);

        // Explicit "Less than 1 min" localized display rule
        expect(find.text('Less than 1 min'), findsOneWidget);

        // Does NOT display "0 min"
        expect(find.text('0 min'), findsNothing);
      },
    );

    testWidgets(
      'J. Later-calendar-day: +1 indicator visible and accessible with "next day" semantics',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpJourneySearchTest(
          tester,
          fixedNow: DateTime(2026, 1, 5, 23, 0), // 23:00 Monday
          initialBoardingStopId: StopId('stop_alpha_1'),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Select Central Station (trip_next_day runs 23:45 -> 24:15 / 00:15 next day)
        await tester.tap(findToSearchBar());
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('stop_suggestion_stop_central')),
        );
        await tester.pumpAndSettle();

        // +1 marker is rendered
        expect(find.text('+1'), findsOneWidget);

        // Semantics "next day" is accessible
        final semanticsHandle = tester.ensureSemantics();
        expect(
          tester.getSemantics(find.text('+1')).label,
          contains('next day'),
        );
        semanticsHandle.dispose();
      },
    );

    testWidgets(
      'K. next-later state: passenger-friendly later-service wording, no raw "nextLater"',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        // Query time: Tuesday 10:00 - all Tuesday trips to Beta Junction (09:00) have departed. Wednesday trip is in nextLater.
        await pumpJourneySearchTest(
          tester,
          fixedNow: DateTime(2026, 1, 6, 10, 0), // Tuesday 10:00
          initialBoardingStopId: StopId('stop_alpha_1'),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Select destination = Beta Junction (only runs 09:00)
        await tester.tap(findToSearchBar());
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('stop_suggestion_stop_beta')),
        );
        await tester.pumpAndSettle();

        // Next-later notice is displayed
        expect(
          find.text('No more scheduled journeys for today'),
          findsOneWidget,
        );
        expect(find.text('Next scheduled journeys'), findsOneWidget);

        // No raw domain term "nextLater"
        expect(find.textContaining('nextLater'), findsNothing);

        // Shows scheduled departure with date (e.g. "Wed, Jan 7 · 9:00 AM")
        expect(find.textContaining('Jan 7'), findsOneWidget);
      },
    );

    testWidgets(
      'L. Empty state: no direct scheduled journeys between stop pair',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        await pumpJourneySearchTest(
          tester,
          initialBoardingStopId: StopId('stop_central'),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Central -> Beta Junction has no direct trips in the timetable
        await tester.tap(findToSearchBar());
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('stop_suggestion_stop_beta')),
        );
        await tester.pumpAndSettle();

        // Empty state is rendered
        expect(find.text('No direct scheduled journeys'), findsOneWidget);
        expect(
          find.text(
            'No direct scheduled buses were found between these stops in the current timetable.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('M. Loading state: accessible progress indicator rendered', (
      tester,
    ) async {
      final completer = Completer<Timetable>();
      final fakeRepo = FakeTimetableRepository(completer: completer);

      await pumpJourneySearchTest(
        tester,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      // Loading view is rendered
      expect(find.byType(GtLoadingView), findsOneWidget);
      expect(find.byType(JourneyStopSelector), findsNothing);

      completer.complete(createJourneyTestTimetable());
      await tester.pumpAndSettle();

      expect(find.byType(GtLoadingView), findsNothing);
      expect(find.byType(JourneyStopSelector), findsNWidgets(2));
    });

    testWidgets(
      'N. Error state: passenger-friendly error rendered with retry',
      (tester) async {
        final failure = DataFormatFailure(
          cause: 'Corrupt JSON',
          stackTrace: StackTrace.current,
        );
        final fakeRepo = FakeTimetableRepository(error: failure);

        await pumpJourneySearchTest(
          tester,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        // Error view rendered with localized message, no raw exception
        expect(find.byType(GtErrorView), findsOneWidget);
        expect(
          find.text('The timetable data could not be loaded.'),
          findsOneWidget,
        );
        expect(find.textContaining('StackTrace'), findsNothing);

        // Retry
        fakeRepo.error = null;
        fakeRepo.timetable = createJourneyTestTimetable();

        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(find.byType(GtErrorView), findsNothing);
        expect(find.byType(JourneyStopSelector), findsNWidgets(2));
      },
    );

    testWidgets(
      'P. Accessibility: large text scale and dark theme smoke test',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        // Large text (2.0x scale) in Dark mode
        await pumpJourneySearchTest(
          tester,
          textScaleFactor: 2.0,
          themeMode: ThemeMode.dark,
          initialBoardingStopId: StopId('stop_alpha_1'),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.text('Alpha Central'), findsOneWidget);
        expect(find.byType(JourneyStopSelector), findsNWidgets(2));
      },
    );

    testWidgets(
      'Q. Boundary: JourneySearchScreen is pumped directly with no GoRouter and no Home modification',
      (tester) async {
        final timetable = createJourneyTestTimetable();
        final fakeRepo = FakeTimetableRepository(timetable: timetable);

        // Directly pumpable without routing registration
        await pumpJourneySearchTest(
          tester,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
      },
    );
  });
}
