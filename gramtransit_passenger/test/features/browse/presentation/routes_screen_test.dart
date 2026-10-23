import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/features/browse/presentation/routes_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_sample_data_notice.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

import '../browse_test_support.dart';

void main() {
  group('RoutesScreen (P3.5)', () {
    testWidgets('1. loading state renders GtLoadingView', (tester) async {
      final completer = Completer<Timetable>();
      final fakeRepo = FakeBrowseTimetableRepository(completer: completer);

      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );

      expect(find.byType(GtLoadingView), findsOneWidget);
    });

    testWidgets('2. timetable error state renders GtErrorView', (tester) async {
      final fakeRepo = FakeBrowseTimetableRepository(
        error: const DataFormatFailure(),
      );

      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
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
        child: const RoutesScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtErrorView), findsOneWidget);
      expect(fakeRepo.loadCount, equals(1));

      // Resolve error and retry
      fakeRepo.error = null;
      fakeRepo.timetable = createBrowseTestTimetable();

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(fakeRepo.loadCount, equals(2));
      expect(find.byType(GtErrorView), findsNothing);
      expect(find.text('101'), findsOneWidget);
      expect(find.text('City Center - North Station'), findsOneWidget);
    });

    testWidgets('4. canonical route order is preserved', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // Verify all canonical routes are rendered
      expect(find.text('101'), findsOneWidget);
      expect(find.text('102'), findsOneWidget);
      expect(find.text('999'), findsOneWidget);

      // Verify order on screen: 101, then 102, then 999
      final shortNameWidgets = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byType(ListView),
              matching: find.byType(Text),
            ),
          )
          .map((t) => t.data)
          .where((text) => text == '101' || text == '102' || text == '999')
          .toList();

      expect(shortNameWidgets, equals(['101', '102', '999']));
    });

    testWidgets('5. zero-trip route remains listed', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      // route_unused has 0 trips in default timetable
      expect(find.text('999'), findsOneWidget);
      expect(find.text('Unused Route'), findsOneWidget);
    });

    testWidgets('6. sample notice shown for sample data', (tester) async {
      final timetable = createBrowseTestTimetable(isSampleData: true);
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseSampleDataNotice), findsOneWidget);
      expect(
        find.text('Sample timetable for testing — not for real travel.'),
        findsOneWidget,
      );
    });

    testWidgets('7. sample notice absent for non-sample data', (tester) async {
      final timetable = createBrowseTestTimetable(isSampleData: false);
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(BrowseSampleDataNotice), findsNothing);
    });

    testWidgets('8. route callback receives correct RouteId', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);
      RouteId? tappedRouteId;

      await pumpBrowseTest(
        tester,
        child: RoutesScreen(onRouteTap: (id) => tappedRouteId = id),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('101'));
      expect(tappedRouteId, equals(RouteId('route_1')));

      await tester.tap(find.text('102'));
      expect(tappedRouteId, equals(RouteId('route_2')));
    });

    testWidgets('9. callback-null state does not navigate/crash', (
      tester,
    ) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(onRouteTap: null),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('101'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. 360dp / 200% text no overflow', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
        surfaceSize: const Size(360, 640),
        textScaleFactor: 2.0,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('101'), findsOneWidget);
    });

    testWidgets('11. light/dark smoke', (tester) async {
      final timetable = createBrowseTestTimetable();
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      // Light theme
      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
        themeMode: ThemeMode.light,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();
      expect(find.text('101'), findsOneWidget);

      // Dark theme
      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
        themeMode: ThemeMode.dark,
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();
      expect(find.text('101'), findsOneWidget);
    });

    testWidgets('routes list empty state renders GtEmptyState', (tester) async {
      final timetable = createBrowseTestTimetable(routes: []);
      final fakeRepo = FakeBrowseTimetableRepository(timetable: timetable);

      await pumpBrowseTest(
        tester,
        child: const RoutesScreen(),
        overrides: [timetableRepositoryProvider.overrideWithValue(fakeRepo)],
      );
      await tester.pumpAndSettle();

      expect(find.byType(GtEmptyState), findsOneWidget);
      expect(find.text('No routes available'), findsOneWidget);
    });
  });
}
