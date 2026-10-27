import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';
import 'package:gramtransit_passenger/features/browse/presentation/stop_details_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_sample_data_notice.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_scheduled_times_note.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/stop_upcoming_trip_card.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

import '../browse_test_support.dart';

void main() {
  group('StopDetailsScreen (P3.4)', () {
    testWidgets('12. loading renders GtLoadingView', (tester) async {
      final completer = Completer<Timetable>();
      final fakeRepo = FakeBrowseTimetableRepository(completer: completer);

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
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
        child: StopDetailsScreen(stopId: StopId('stop_1')),
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
        child: StopDetailsScreen(stopId: StopId('stop_1')),
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
      expect(find.text('City Center'), findsOneWidget);
    });

    testWidgets('15. unknown stop -> not-found empty state', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
      var backPressed = false;

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(
          stopId: StopId('stop_nonexistent'),
          onBack: () => backPressed = true,
        ),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtEmptyState), findsOneWidget);
      expect(find.text('Stop not found'), findsOneWidget);
      expect(
        find.text("This stop isn't in the current timetable."),
        findsOneWidget,
      );

      await tester.tap(find.text('Go to Home'));
      await tester.pumpAndSettle();
      expect(backPressed, isTrue);
    });

    testWidgets(
      '16. unknown stop does not trigger/use upcoming departures or sample notice',
      (tester) async {
        final timetable = createBrowseTestTimetable(isSampleData: true);
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

        await pumpBrowseTest(
          tester,
          child: StopDetailsScreen(stopId: StopId('stop_nonexistent')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.text('Upcoming departures'), findsNothing);
        expect(find.byType(BrowseScheduledTimesNote), findsNothing);
        expect(find.byType(BrowseSampleDataNotice), findsNothing);
        expect(find.byType(StopUpcomingTripCard), findsNothing);
      },
    );

    testWidgets('17. canonical stop header displays stop name', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('City Center'), findsOneWidget);
    });

    testWidgets('18. sample notice shown only for sample data', (tester) async {
      // With isSampleData: true
      final sampleTimetable = createBrowseTestTimetable(isSampleData: true);
      final fakeRepo1 = FakeBrowseTimetableRepository(
        timetable: sampleTimetable,
      );

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo1)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseSampleDataNotice), findsOneWidget);
      expect(
        find.text('Sample timetable for testing — not for real travel.'),
        findsOneWidget,
      );

      // With isSampleData: false
      final nonSampleTimetable = createBrowseTestTimetable(isSampleData: false);
      final fakeRepo2 = FakeBrowseTimetableRepository(
        timetable: nonSampleTimetable,
      );

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo2)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseSampleDataNotice), findsNothing);
      expect(
        find.text('Sample timetable for testing — not for real travel.'),
        findsNothing,
      );
    });

    testWidgets('19. Plan journey callback receives correct StopId', (
      tester,
    ) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
      StopId? plannedStopId;

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(
          stopId: StopId('stop_2'),
          onPlanJourney: (id) => plannedStopId = id,
        ),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Plan journey from here'), findsOneWidget);
      await tester.tap(find.text('Plan journey from here'));
      await tester.pumpAndSettle();

      expect(plannedStopId, equals(StopId('stop_2')));
    });

    testWidgets('20. routes preserve StopDetails ordering', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Routes serving this stop'), findsOneWidget);
      expect(find.text('101'), findsOneWidget);
      expect(find.text('102'), findsOneWidget);

      // Check relative order of 101 before 102
      final pos101 = tester.getTopLeft(find.text('101')).dy;
      final pos102 = tester.getTopLeft(find.text('102')).dy;
      expect(pos101, lessThan(pos102));
    });

    testWidgets(
      '21. known unused stop / zero routes has explicit empty state',
      (tester) async {
        final timetable = createBrowseTestTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

        await pumpBrowseTest(
          tester,
          child: StopDetailsScreen(stopId: StopId('stop_unused')),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.text('Routes serving this stop'), findsOneWidget);
        expect(
          find.text('No routes currently serve this stop'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '22. upcoming scheduled departures render using existing provider semantics',
      (tester) async {
        final timetable = createBrowseTestTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
        TripId? tappedTripId;

        // Current test time is 07:30 UTC; trips depart at 08:05 and 09:05
        await pumpBrowseTest(
          tester,
          child: StopDetailsScreen(
            stopId: StopId('stop_1'),
            onTripTap: (id) => tappedTripId = id,
          ),
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(find.text('Upcoming departures'), findsOneWidget);
        expect(find.byType(StopUpcomingTripCard), findsNWidgets(2));
        expect(find.text('To North Station'), findsOneWidget);
        expect(find.text('To Market Square'), findsOneWidget);

        // Tap first trip card
        await tester.tap(find.text('To North Station'));
        await tester.pumpAndSettle();

        expect(tappedTripId, equals(TripId('trip_1')));
      },
    );

    testWidgets('23. scheduled-times disclosure is present with departures', (
      tester,
    ) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseScheduledTimesNote), findsOneWidget);
      expect(
        find.text('Scheduled times. Actual times may vary.'),
        findsOneWidget,
      );
    });

    testWidgets('24. no realtime/ETA/live wording is introduced', (
      tester,
    ) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
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

    testWidgets('25. 200% text scale at 360dp width renders without overflow', (
      tester,
    ) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
        surfaceSize: const Size(360, 640),
        textScaleFactor: 2.0,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('City Center'), findsOneWidget);
      expect(find.text('Plan journey from here'), findsOneWidget);
    });

    testWidgets('26. light and dark themes render cleanly', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      // Light theme
      await pumpBrowseTest(
        tester,
        themeMode: ThemeMode.light,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();
      expect(find.text('City Center'), findsOneWidget);

      // Dark theme
      await pumpBrowseTest(
        tester,
        themeMode: ThemeMode.dark,
        child: StopDetailsScreen(stopId: StopId('stop_1')),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();
      expect(find.text('City Center'), findsOneWidget);
    });

    group('P4.3: Detail Save / Unsave Controls', () {
      testWidgets('1. unsaved stop shows outlined bookmark action', (
        tester,
      ) async {
        final timetable = createBrowseTestTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
        final store = InMemoryKeyValueStore();

        await pumpBrowseTest(
          tester,
          child: StopDetailsScreen(stopId: StopId('stop_1')),
          overrides: [
            timetableRepositoryProvider.overrideWithValue(fakeRepo),
            keyValueStoreProvider.overrideWithValue(store),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
      });

      testWidgets('2. unsaved action exposes "Save stop"', (tester) async {
        final timetable = createBrowseTestTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
        final store = InMemoryKeyValueStore();

        await pumpBrowseTest(
          tester,
          child: StopDetailsScreen(stopId: StopId('stop_1')),
          overrides: [
            timetableRepositoryProvider.overrideWithValue(fakeRepo),
            keyValueStoreProvider.overrideWithValue(store),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Save stop'), findsOneWidget);
        expect(
          tester.widget<IconButton>(find.byType(IconButton)).tooltip,
          equals('Save stop'),
        );
      });

      testWidgets('3. tapping Save stop updates UI to saved/filled state', (
        tester,
      ) async {
        final timetable = createBrowseTestTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
        final store = InMemoryKeyValueStore();

        await pumpBrowseTest(
          tester,
          child: StopDetailsScreen(stopId: StopId('stop_1')),
          overrides: [
            timetableRepositoryProvider.overrideWithValue(fakeRepo),
            keyValueStoreProvider.overrideWithValue(store),
          ],
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byTooltip('Save stop'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
        expect(find.byTooltip('Remove saved stop'), findsOneWidget);
      });

      testWidgets('4. saved stop initially shows filled bookmark', (
        tester,
      ) async {
        final timetable = createBrowseTestTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
        final store = InMemoryKeyValueStore(
          initial: {
            'gt.saved.transit': jsonEncode({
              'version': 1,
              'stops': ['stop_1'],
              'routes': <String>[],
            }),
          },
        );

        await pumpBrowseTest(
          tester,
          child: StopDetailsScreen(stopId: StopId('stop_1')),
          overrides: [
            timetableRepositoryProvider.overrideWithValue(fakeRepo),
            keyValueStoreProvider.overrideWithValue(store),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
        expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
      });

      testWidgets('5. saved action exposes "Remove saved stop"', (
        tester,
      ) async {
        final timetable = createBrowseTestTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
        final store = InMemoryKeyValueStore(
          initial: {
            'gt.saved.transit': jsonEncode({
              'version': 1,
              'stops': ['stop_1'],
              'routes': <String>[],
            }),
          },
        );

        await pumpBrowseTest(
          tester,
          child: StopDetailsScreen(stopId: StopId('stop_1')),
          overrides: [
            timetableRepositoryProvider.overrideWithValue(fakeRepo),
            keyValueStoreProvider.overrideWithValue(store),
          ],
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Remove saved stop'), findsOneWidget);
        expect(
          tester.widget<IconButton>(find.byType(IconButton)).tooltip,
          equals('Remove saved stop'),
        );
      });

      testWidgets(
        '6. tapping Remove saved stop updates UI to unsaved/outlined state',
        (tester) async {
          final timetable = createBrowseTestTimetable();
          final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
          final store = InMemoryKeyValueStore(
            initial: {
              'gt.saved.transit': jsonEncode({
                'version': 1,
                'stops': ['stop_1'],
                'routes': <String>[],
              }),
            },
          );

          await pumpBrowseTest(
            tester,
            child: StopDetailsScreen(stopId: StopId('stop_1')),
            overrides: [
              timetableRepositoryProvider.overrideWithValue(fakeRepo),
              keyValueStoreProvider.overrideWithValue(store),
            ],
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip('Remove saved stop'));
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
          expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
          expect(find.byTooltip('Save stop'), findsOneWidget);
        },
      );

      testWidgets(
        '7. StorageFailure on save: retains optimistic saved state and displays failure SnackBar',
        (tester) async {
          final timetable = createBrowseTestTimetable();
          final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
          final store = FailingWriteKeyValueStore();

          await pumpBrowseTest(
            tester,
            child: StopDetailsScreen(stopId: StopId('stop_1')),
            overrides: [
              timetableRepositoryProvider.overrideWithValue(fakeRepo),
              keyValueStoreProvider.overrideWithValue(store),
            ],
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);

          await tester.tap(find.byTooltip('Save stop'));
          await tester.pump();
          await tester.pumpAndSettle();

          // Retain optimistic saved state
          expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
          expect(find.byIcon(Icons.bookmark_border_rounded), findsNothing);
          expect(find.byTooltip('Remove saved stop'), findsOneWidget);

          // Shows failure SnackBar with localized error
          expect(find.byType(SnackBar), findsOneWidget);
          expect(
            find.text("We couldn't save this on your device."),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '8. StorageFailure on unsave: retains optimistic unsaved state and displays failure SnackBar',
        (tester) async {
          final timetable = createBrowseTestTimetable();
          final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
          final store = FailingWriteKeyValueStore(
            initial: {
              'gt.saved.transit': jsonEncode({
                'version': 1,
                'stops': ['stop_1'],
                'routes': <String>[],
              }),
            },
          );

          await pumpBrowseTest(
            tester,
            child: StopDetailsScreen(stopId: StopId('stop_1')),
            overrides: [
              timetableRepositoryProvider.overrideWithValue(fakeRepo),
              keyValueStoreProvider.overrideWithValue(store),
            ],
          );
          await tester.pumpAndSettle();

          expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);

          await tester.tap(find.byTooltip('Remove saved stop'));
          await tester.pump();
          await tester.pumpAndSettle();

          // Retain optimistic unsaved state
          expect(find.byIcon(Icons.bookmark_border_rounded), findsOneWidget);
          expect(find.byIcon(Icons.bookmark_rounded), findsNothing);
          expect(find.byTooltip('Save stop'), findsOneWidget);

          // Shows failure SnackBar with localized error
          expect(find.byType(SnackBar), findsOneWidget);
          expect(
            find.text("We couldn't save this on your device."),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        'accessibility: bookmark action meets target size and renders in 200% text scale and dark theme',
        (tester) async {
          final timetable = createBrowseTestTimetable();
          final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
          final store = InMemoryKeyValueStore();

          await pumpBrowseTest(
            tester,
            themeMode: ThemeMode.dark,
            surfaceSize: const Size(360, 640),
            textScaleFactor: 2.0,
            child: StopDetailsScreen(stopId: StopId('stop_1')),
            overrides: [
              timetableRepositoryProvider.overrideWithValue(fakeRepo),
              keyValueStoreProvider.overrideWithValue(store),
            ],
          );
          await tester.pumpAndSettle();

          final bookmarkButton = find.byTooltip('Save stop');
          expect(bookmarkButton, findsOneWidget);
          final size = tester.getSize(bookmarkButton);
          expect(size.width, greaterThanOrEqualTo(48.0));
          expect(size.height, greaterThanOrEqualTo(48.0));
        },
      );
    });
  });
}
