import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/app/gramtransit_app.dart';
import 'package:gramtransit_passenger/app/router/app_router.dart';
import 'package:gramtransit_passenger/app/router/route_not_found_screen.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';
import 'package:gramtransit_passenger/core/time/time_providers.dart';
import 'package:gramtransit_passenger/features/browse/presentation/route_details_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/routes_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/stop_details_screen.dart';
import 'package:gramtransit_passenger/features/browse/presentation/stops_screen.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_screen.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/journey_search_screen.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/trip_details_screen.dart';

class _FakeBrowseNavRepository implements TimetableRepository {
  _FakeBrowseNavRepository(this.timetable);
  final Timetable timetable;

  @override
  Future<Timetable> loadTimetable() async => timetable;
}

Timetable _createTestTimetable() {
  return Timetable(
    info: TimetableInfo(datasetVersion: 'v1', isSampleData: true),
    stops: [
      TransitStop(
        id: StopId('stop_1'),
        name: LocalizedText(english: 'City Center'),
      ),
      TransitStop(
        id: StopId('stop_2'),
        name: LocalizedText(english: 'North Station'),
      ),
    ],
    routes: [
      TransitRoute(
        id: RouteId('route_1'),
        shortName: LocalizedText(english: '101'),
        longName: LocalizedText(english: 'City Center to North Station'),
      ),
    ],
    trips: [
      ScheduledTrip(
        id: TripId('trip_1'),
        routeId: RouteId('route_1'),
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
            arrivalTime: ServiceTime(hour: 8, minute: 0),
            departureTime: ServiceTime(hour: 8, minute: 5),
          ),
          StopTime(
            stopId: StopId('stop_2'),
            arrivalTime: ServiceTime(hour: 8, minute: 30),
            departureTime: ServiceTime(hour: 8, minute: 35),
          ),
        ],
      ),
    ],
  );
}

void main() {
  Future<void> pumpNavigationApp(
    WidgetTester tester, {
    Timetable? timetable,
    DateTime? fixedNow,
  }) async {
    final effectiveNow = fixedNow ?? DateTime(2026, 10, 14, 7, 50); // Wednesday
    final effectiveTimetable = timetable ?? _createTestTimetable();
    final fakeRepo = _FakeBrowseNavRepository(effectiveTimetable);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
          timetableRepositoryProvider.overrideWithValue(fakeRepo),
          minuteTickerProvider.overrideWith(
            (ref) => Stream<DateTime>.value(effectiveNow),
          ),
        ],
        child: const GramTransitApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Browse Navigation Integration', () {
    testWidgets('1. /stops resolves to StopsScreen', (tester) async {
      await pumpNavigationApp(tester);

      final router = ProviderScope.containerOf(
        tester.element(find.byType(GramTransitApp)),
      ).read(routerProvider);

      router.go('/stops');
      await tester.pumpAndSettle();

      expect(find.byType(StopsScreen), findsOneWidget);
      expect(find.text('Stops'), findsOneWidget);
      expect(find.text('City Center'), findsOneWidget);
      expect(find.text('North Station'), findsOneWidget);
    });

    testWidgets(
      '2. /stops/:stopId resolves to StopDetailsScreen with correct StopId',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/stops/stop_1');
        await tester.pumpAndSettle();

        expect(find.byType(StopDetailsScreen), findsOneWidget);
        final detailsWidget = tester.widget<StopDetailsScreen>(
          find.byType(StopDetailsScreen),
        );
        expect(detailsWidget.stopId, StopId('stop_1'));
        expect(find.text('City Center'), findsWidgets);
      },
    );

    testWidgets('3. /routes resolves to RoutesScreen', (tester) async {
      await pumpNavigationApp(tester);

      final router = ProviderScope.containerOf(
        tester.element(find.byType(GramTransitApp)),
      ).read(routerProvider);

      router.go('/routes');
      await tester.pumpAndSettle();

      expect(find.byType(RoutesScreen), findsOneWidget);
      expect(find.text('Routes'), findsOneWidget);
      expect(find.text('101'), findsOneWidget);
      expect(find.text('City Center to North Station'), findsOneWidget);
    });

    testWidgets(
      '4. /routes/:routeId resolves to RouteDetailsScreen with correct RouteId',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/routes/route_1');
        await tester.pumpAndSettle();

        expect(find.byType(RouteDetailsScreen), findsOneWidget);
        final detailsWidget = tester.widget<RouteDetailsScreen>(
          find.byType(RouteDetailsScreen),
        );
        expect(detailsWidget.routeId, RouteId('route_1'));
        expect(find.text('101'), findsWidgets);
        expect(find.text('City Center to North Station'), findsWidgets);
      },
    );

    testWidgets('5. invalid StopId parsing follows frozen not-found behavior', (
      tester,
    ) async {
      await pumpNavigationApp(tester);

      final router = ProviderScope.containerOf(
        tester.element(find.byType(GramTransitApp)),
      ).read(routerProvider);

      router.go('/stops/%20');
      await tester.pumpAndSettle();

      expect(find.byType(GtEmptyState), findsOneWidget);
      expect(find.text('Stop not found'), findsOneWidget);
      expect(
        find.text("This stop isn't in the current timetable."),
        findsOneWidget,
      );
    });

    testWidgets(
      '6. invalid RouteId parsing follows frozen not-found behavior',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/routes/%20');
        await tester.pumpAndSettle();

        expect(find.byType(GtEmptyState), findsOneWidget);
        expect(find.text('Route not found'), findsOneWidget);
        expect(
          find.text("This route isn't in the current timetable."),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6a. /stops/<unknown-id> directly resolves to StopDetailsScreen with not-found state',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/stops/stop_missing');
        await tester.pumpAndSettle();

        // StopId parsing succeeded and StopDetailsScreen was reached
        expect(find.byType(StopDetailsScreen), findsOneWidget);
        final detailsWidget = tester.widget<StopDetailsScreen>(
          find.byType(StopDetailsScreen),
        );
        expect(detailsWidget.stopId, StopId('stop_missing'));

        // stopDetailsProvider resolved to null -> established Browse not-found UI rendered
        expect(find.byType(GtEmptyState), findsOneWidget);
        expect(find.text('Stop not found'), findsOneWidget);
        expect(
          find.text("This stop isn't in the current timetable."),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6b. /routes/<unknown-id> directly resolves to RouteDetailsScreen with not-found state',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/routes/route_missing');
        await tester.pumpAndSettle();

        // RouteId parsing succeeded and RouteDetailsScreen was reached
        expect(find.byType(RouteDetailsScreen), findsOneWidget);
        final detailsWidget = tester.widget<RouteDetailsScreen>(
          find.byType(RouteDetailsScreen),
        );
        expect(detailsWidget.routeId, RouteId('route_missing'));

        // routeDetailsProvider resolved to null -> established Browse not-found UI rendered
        expect(find.byType(GtEmptyState), findsOneWidget);
        expect(find.text('Route not found'), findsOneWidget);
        expect(
          find.text("This route isn't in the current timetable."),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '7. StopsScreen callback navigates using registered Stop Details route',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/stops');
        await tester.pumpAndSettle();

        // Tap on City Center
        await tester.tap(find.text('City Center'));
        await tester.pumpAndSettle();

        expect(find.byType(StopDetailsScreen), findsOneWidget);
        final details = tester.widget<StopDetailsScreen>(
          find.byType(StopDetailsScreen),
        );
        expect(details.stopId, StopId('stop_1'));
      },
    );

    testWidgets(
      '8. RoutesScreen callback navigates using registered Route Details route',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/routes');
        await tester.pumpAndSettle();

        // Tap on Route 101
        await tester.tap(find.text('101'));
        await tester.pumpAndSettle();

        expect(find.byType(RouteDetailsScreen), findsOneWidget);
        final details = tester.widget<RouteDetailsScreen>(
          find.byType(RouteDetailsScreen),
        );
        expect(details.routeId, RouteId('route_1'));
      },
    );

    testWidgets(
      '9. Stop Details Plan journey navigates to Journey Search with FROM prefilled',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/stops/stop_1');
        await tester.pumpAndSettle();

        // Tap "Plan journey from here"
        await tester.tap(find.text('Plan journey from here'));
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        // FROM stop prefilled with City Center
        expect(find.text('City Center'), findsOneWidget);
        expect(find.text('Choose destination stop'), findsOneWidget);
      },
    );

    testWidgets(
      '10. Stop Details trip tap navigates to Trip Details with correct TripId',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/stops/stop_1');
        await tester.pumpAndSettle();

        // Tap upcoming departure trip card
        await tester.tap(find.text('8:05 AM'));
        await tester.pumpAndSettle();

        expect(find.byType(TripDetailsScreen), findsOneWidget);
        final tripDetails = tester.widget<TripDetailsScreen>(
          find.byType(TripDetailsScreen),
        );
        expect(tripDetails.tripId, TripId('trip_1'));
      },
    );

    testWidgets(
      '11. Route Details trip tap navigates to Trip Details with correct TripId',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/routes/route_1');
        await tester.pumpAndSettle();

        // Tap scheduled trip row
        await tester.tap(find.text('8:05 AM'));
        await tester.pumpAndSettle();

        expect(find.byType(TripDetailsScreen), findsOneWidget);
        final tripDetails = tester.widget<TripDetailsScreen>(
          find.byType(TripDetailsScreen),
        );
        expect(tripDetails.tripId, TripId('trip_1'));
      },
    );

    testWidgets('12. existing unmatched-route behavior is unchanged', (
      tester,
    ) async {
      await pumpNavigationApp(tester);

      final router = ProviderScope.containerOf(
        tester.element(find.byType(GramTransitApp)),
      ).read(routerProvider);

      router.go('/invalid_unmatched_route_path');
      await tester.pumpAndSettle();

      expect(find.byType(RouteNotFoundScreen), findsOneWidget);
    });

    testWidgets(
      '13. Browse routes are root navigator destinations (no bottom NavigationBar)',
      (tester) async {
        await pumpNavigationApp(tester);

        // On Home, NavigationBar is visible
        expect(find.byType(NavigationBar), findsOneWidget);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        // /stops
        router.go('/stops');
        await tester.pumpAndSettle();
        expect(find.byType(StopsScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        // /routes
        router.go('/routes');
        await tester.pumpAndSettle();
        expect(find.byType(RoutesScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        // /stops/:stopId
        router.go('/stops/stop_1');
        await tester.pumpAndSettle();
        expect(find.byType(StopDetailsScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        // /routes/:routeId
        router.go('/routes/route_1');
        await tester.pumpAndSettle();
        expect(find.byType(RouteDetailsScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      },
    );

    testWidgets(
      '14. Home -> tap All stops -> navigates to StopsScreen -> Back to Home',
      (tester) async {
        await pumpNavigationApp(tester);

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('All stops'), findsOneWidget);

        // Tap "All stops" on Home Explore
        await tester.tap(find.text('All stops'));
        await tester.pumpAndSettle();

        expect(find.byType(StopsScreen), findsOneWidget);

        // Tap back in AppBar
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );

    testWidgets(
      '15. Home -> tap All routes -> navigates to RoutesScreen -> Back to Home',
      (tester) async {
        await pumpNavigationApp(tester);

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('All routes'), findsOneWidget);

        // Tap "All routes" on Home Explore
        await tester.tap(find.text('All routes'));
        await tester.pumpAndSettle();

        expect(find.byType(RoutesScreen), findsOneWidget);

        // Tap back in AppBar
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        expect(find.byType(HomeScreen), findsOneWidget);
      },
    );
  });
}
