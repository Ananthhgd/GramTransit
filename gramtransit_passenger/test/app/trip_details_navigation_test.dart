import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/app/gramtransit_app.dart';
import 'package:gramtransit_passenger/app/router/app_router.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';
import 'package:gramtransit_passenger/core/time/time_providers.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_trip_card.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/trip_details_screen.dart';

import '../features/trip_details/trip_details_test_support.dart';

void main() {
  Future<void> pumpNavigationApp(
    WidgetTester tester, {
    Timetable? timetable,
    DateTime? fixedNow,
  }) async {
    final effectiveNow = fixedNow ?? DateTime(2026, 10, 14, 7, 50); // Wednesday
    final effectiveTimetable = timetable ?? createTripDetailsTestTimetable();
    final fakeRepo = FakeTripDetailsTimetableRepository(
      timetable: effectiveTimetable,
    );

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

  group('Trip Details Navigation', () {
    testWidgets(
      '1. Home -> choose boardable stop -> tap current trip card -> Trip Details',
      (tester) async {
        await pumpNavigationApp(tester);

        // Open stop selector dropdown
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();

        // Select City Center
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        // Upcoming trip card is visible
        expect(find.byType(UpcomingTripCard), findsOneWidget);
        expect(find.text('8:05 AM'), findsOneWidget);

        // Tap the card to navigate
        await tester.tap(find.byType(UpcomingTripCard));
        await tester.pumpAndSettle();

        // Verify Trip Details screen is displayed
        expect(find.byType(TripDetailsScreen), findsOneWidget);
        expect(find.text('Trip details'), findsOneWidget);
        expect(find.text('Route 101'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Back -> returns to Home with the same selected StopId preserved',
      (tester) async {
        await pumpNavigationApp(tester);

        // Select City Center
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        // Navigate to details
        await tester.tap(find.byType(UpcomingTripCard));
        await tester.pumpAndSettle();
        expect(find.byType(TripDetailsScreen), findsOneWidget);

        // Tap Back in AppBar
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Verify we are back on Home and selected stop is preserved
        expect(find.byType(TripDetailsScreen), findsNothing);
        expect(find.text('City Center'), findsOneWidget);
        expect(find.byType(UpcomingTripCard), findsOneWidget);
      },
    );

    testWidgets('3. nextLater card can also navigate to Trip Details', (
      tester,
    ) async {
      // Query time is 22:00 on Wednesday, departure is next morning on Thursday at 08:05
      final timetable = createTripDetailsTestTimetable(
        trips: [
          ScheduledTrip(
            id: TripId('trip_thursday'),
            routeId: RouteId('route_1'),
            serviceDays: const ServiceDays(thursday: true),
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

      await pumpNavigationApp(
        tester,
        timetable: timetable,
        fixedNow: DateTime(2026, 10, 14, 22, 0), // Wednesday night
      );

      // Select City Center
      await tester.tap(find.byType(DropdownButton<StopId>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('City Center').last);
      await tester.pumpAndSettle();

      // nextLater card is shown with dated departure
      expect(find.text('Next scheduled bus'), findsOneWidget);
      expect(find.byType(UpcomingTripCard), findsOneWidget);

      // Tap nextLater card
      await tester.tap(find.byType(UpcomingTripCard));
      await tester.pumpAndSettle();

      // Navigated to Trip Details
      expect(find.byType(TripDetailsScreen), findsOneWidget);
      expect(find.text('Route 101'), findsOneWidget);
    });

    testWidgets('4. /trips/<known-id> directly resolves to Trip Details', (
      tester,
    ) async {
      await pumpNavigationApp(tester);

      final router = ProviderScope.containerOf(
        tester.element(find.byType(GramTransitApp)),
      ).read(routerProvider);

      router.go('/trips/trip_1');
      await tester.pumpAndSettle();

      expect(find.byType(TripDetailsScreen), findsOneWidget);
      expect(find.text('Route 101'), findsOneWidget);
      expect(find.text('City Center to North Station'), findsOneWidget);
    });

    testWidgets(
      '5. /trips/<unknown-id> directly resolves to Trip Details not-found state',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/trips/unknown_trip_999');
        await tester.pumpAndSettle();

        expect(find.byType(TripDetailsScreen), findsOneWidget);
        expect(find.byType(GtEmptyState), findsOneWidget);
        expect(find.text('Trip not found'), findsOneWidget);
        expect(
          find.text("This trip isn't in the current timetable."),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6. Trip Details is above the shell; bottom navigation is not displayed',
      (tester) async {
        await pumpNavigationApp(tester);

        // On Home, bottom navigation bar is visible
        expect(find.byType(NavigationBar), findsOneWidget);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/trips/trip_1');
        await tester.pumpAndSettle();

        // On Trip Details, bottom navigation bar must NOT be displayed
        expect(find.byType(TripDetailsScreen), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      },
    );
  });
}
