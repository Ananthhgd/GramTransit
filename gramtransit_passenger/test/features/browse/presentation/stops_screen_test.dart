import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/features/browse/presentation/stops_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_sample_data_notice.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

import '../browse_test_support.dart';

void main() {
  group('StopsScreen (P3.4)', () {
    testWidgets('1. loading renders GtLoadingView', (tester) async {
      final completer = Completer<Timetable>();
      final fakeRepo = FakeBrowseTimetableRepository(completer: completer);

      await pumpBrowseTest(
        tester,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      expect(find.byType(GtLoadingView), findsOneWidget);
    });

    testWidgets('2. timetable error renders GtErrorView', (tester) async {
      final fakeRepo = FakeBrowseTimetableRepository(
        error: const DataFormatFailure(),
      );

      await pumpBrowseTest(
        tester,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtErrorView), findsOneWidget);
      expect(
        find.text('The timetable data could not be loaded.'),
        findsOneWidget,
      );
    });

    testWidgets('3. retry path re-fetches timetable', (tester) async {
      final fakeRepo = FakeBrowseTimetableRepository(
        error: const DataFormatFailure(),
      );

      await pumpBrowseTest(
        tester,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtErrorView), findsOneWidget);
      expect(fakeRepo.loadCount, equals(1));

      // Fix repo state and tap retry
      fakeRepo.error = null;
      fakeRepo.timetable = createBrowseTestTimetable();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(fakeRepo.loadCount, equals(2));
      expect(find.byType(GtErrorView), findsNothing);
      expect(find.text('City Center'), findsOneWidget);
    });

    testWidgets('4. canonical all-stop order for blank query', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      final stopFinder = find.descendant(
        of: find.byType(ListView),
        matching: find.byType(InkWell),
      );
      expect(stopFinder, findsNWidgets(4));

      // Verify canonical order: City Center, North Station, Market Square, Unused Stop
      final textWidgets = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .toList();

      expect(textWidgets[0], equals('City Center'));
      expect(textWidgets[1], equals('North Station'));
      expect(textWidgets[2], equals('Market Square'));
      expect(textWidgets[3], equals('Unused Stop'));
    });

    testWidgets('5. unused stop remains visible', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.text('Unused Stop'), findsOneWidget);
    });

    testWidgets('6. search reuses expected search behavior/result', (
      tester,
    ) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Enter search query
      await tester.enterText(find.byType(SearchBar), 'North');
      await tester.pumpAndSettle();

      expect(find.text('North Station'), findsOneWidget);
      expect(find.text('City Center'), findsNothing);
      expect(find.text('Market Square'), findsNothing);
      expect(find.text('Unused Stop'), findsNothing);

      // Clear search query restores canonical list
      await tester.tap(find.byIcon(Icons.clear_rounded));
      await tester.pumpAndSettle();

      expect(find.text('City Center'), findsOneWidget);
      expect(find.text('North Station'), findsOneWidget);
      expect(find.text('Market Square'), findsOneWidget);
      expect(find.text('Unused Stop'), findsOneWidget);
    });

    testWidgets('7. no-match state is explicit and accessible', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(SearchBar), 'xyz999nonexistent');
      await tester.pumpAndSettle();

      expect(find.text('No stops found'), findsOneWidget);
      expect(find.byIcon(Icons.search_off_rounded), findsOneWidget);
    });

    testWidgets('8. sample notice shown for sample data', (tester) async {
      final timetable = createBrowseTestTimetable(isSampleData: true);
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseSampleDataNotice), findsOneWidget);
      expect(
        find.text('Sample timetable for testing — not for real travel.'),
        findsOneWidget,
      );
    });

    testWidgets('9. sample notice absent for non-sample data', (tester) async {
      final timetable = createBrowseTestTimetable(isSampleData: false);
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseSampleDataNotice), findsNothing);
      expect(
        find.text('Sample timetable for testing — not for real travel.'),
        findsNothing,
      );
    });

    testWidgets('10. stop row callback receives the correct canonical StopId', (
      tester,
    ) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
      StopId? tappedStopId;

      await pumpBrowseTest(
        tester,
        child: StopsScreen(
          onStopTap: (stopId) {
            tappedStopId = stopId;
          },
        ),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('North Station'));
      await tester.pumpAndSettle();

      expect(tappedStopId, equals(StopId('stop_2')));
    });

    testWidgets(
      '11. accessibility: 200% text scale at 360dp width renders without overflow',
      (tester) async {
        final timetable = createBrowseTestTimetable();
        final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

        await pumpBrowseTest(
          tester,
          child: const StopsScreen(),
          surfaceSize: const Size(360, 640),
          textScaleFactor: 2.0,
          overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Stops'), findsOneWidget);
        expect(find.text('City Center'), findsOneWidget);
      },
    );

    testWidgets('11b. light and dark themes render cleanly', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      // Light theme
      await pumpBrowseTest(
        tester,
        themeMode: ThemeMode.light,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();
      expect(find.text('Stops'), findsOneWidget);

      // Dark theme
      await pumpBrowseTest(
        tester,
        themeMode: ThemeMode.dark,
        child: const StopsScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();
      expect(find.text('Stops'), findsOneWidget);
    });
  });
}
