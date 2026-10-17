import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/app/gramtransit_app.dart';
import 'package:gramtransit_passenger/app/router/app_router.dart';
import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';
import 'package:gramtransit_passenger/core/time/time_providers.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_screen.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/search_entry_placeholder.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/journey_search_screen.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/scheduled_journey_card.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

class _FakeNavigationTimetableRepository implements TimetableRepository {
  _FakeNavigationTimetableRepository(this.timetable);
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
      TransitStop(
        id: StopId('stop_3'),
        name: LocalizedText(english: 'South Terminal'),
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
    final fakeRepo = _FakeNavigationTimetableRepository(effectiveTimetable);

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

  group('Journey Search Navigation & Routing (P2.6)', () {
    testWidgets(
      '1. Home without selected stop -> tap Search -> /journeys opens with unselected From',
      (tester) async {
        await pumpNavigationApp(tester);

        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.byType(SearchEntryPlaceholder), findsOneWidget);

        // Tap search pill on Home
        await tester.tap(find.byType(SearchEntryPlaceholder));
        await tester.pumpAndSettle();

        // Journey Search screen is open
        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.text('Choose starting stop'), findsOneWidget);
        expect(find.text('Choose destination stop'), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);
      },
    );

    testWidgets(
      '2. Home with selected stop -> tap Search -> /journeys?from=<id> opens with From prefilled',
      (tester) async {
        await pumpNavigationApp(tester);

        // Select City Center
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        // Tap search pill
        await tester.tap(find.byType(SearchEntryPlaceholder));
        await tester.pumpAndSettle();

        // Journey Search screen opens with City Center in From
        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.text('City Center'), findsOneWidget);
        expect(find.text('Choose destination stop'), findsOneWidget);
      },
    );

    testWidgets(
      '3. Back from Journey Search -> returns to Home with selected stop preserved',
      (tester) async {
        await pumpNavigationApp(tester);

        // Select City Center
        await tester.tap(find.byType(DropdownButton<StopId>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('City Center').last);
        await tester.pumpAndSettle();

        // Navigate to Journey Search
        await tester.tap(find.byType(SearchEntryPlaceholder));
        await tester.pumpAndSettle();
        expect(find.byType(JourneySearchScreen), findsOneWidget);

        // Tap Back in AppBar
        await tester.tap(find.byType(BackButton));
        await tester.pumpAndSettle();

        // Back on Home with City Center still selected
        expect(find.byType(JourneySearchScreen), findsNothing);
        expect(find.byType(HomeScreen), findsOneWidget);
        expect(find.text('City Center'), findsOneWidget);
      },
    );

    testWidgets(
      '4. Direct navigation: /journeys resolves with null From and null To',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/journeys');
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.text('Choose starting stop'), findsOneWidget);
        expect(find.text('Choose destination stop'), findsOneWidget);
      },
    );

    testWidgets(
      '5. Direct navigation: /journeys?from=stop_1 resolves with From prefilled and To null',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/journeys?from=stop_1');
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.text('City Center'), findsOneWidget);
        expect(find.text('Choose destination stop'), findsOneWidget);
      },
    );

    testWidgets(
      '6. Direct navigation: /journeys?to=stop_2 resolves with From null and To prefilled',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/journeys?to=stop_2');
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.text('Choose starting stop'), findsOneWidget);
        expect(find.text('North Station'), findsOneWidget);
      },
    );

    testWidgets(
      '7. Direct navigation: /journeys?from=stop_1&to=stop_2 prefills both and activates journey results',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/journeys?from=stop_1&to=stop_2');
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.text('City Center'), findsOneWidget);
        expect(find.text('North Station'), findsOneWidget);

        // Journey results activated
        expect(find.byType(ScheduledJourneyCard), findsWidgets);
        expect(find.textContaining('Route 101'), findsWidgets);
      },
    );

    testWidgets(
      '8. Syntactically malformed query params -> treated as null without crash',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/journeys?from=%20%20&to=');
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.text('Choose starting stop'), findsOneWidget);
        expect(find.text('Choose destination stop'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Syntactically valid but unknown From -> cleared after timetable load',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/journeys?from=nonexistent_stop&to=stop_2');
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        // From cleared
        expect(find.text('Choose starting stop'), findsOneWidget);
        // To retained
        expect(find.text('North Station'), findsOneWidget);
      },
    );

    testWidgets(
      '10. Syntactically valid but unknown To -> cleared after timetable load',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/journeys?from=stop_1&to=nonexistent_stop');
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        // From retained
        expect(find.text('City Center'), findsOneWidget);
        // To cleared
        expect(find.text('Choose destination stop'), findsOneWidget);
      },
    );

    testWidgets(
      '11. Same known From/To in query -> From retained, To cleared',
      (tester) async {
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/journeys?from=stop_1&to=stop_1');
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.text('City Center'), findsOneWidget);
        expect(find.text('Choose destination stop'), findsOneWidget);
      },
    );

    testWidgets(
      '12. Direct navigation does not require auth, network, backend, maps, or GPS',
      (tester) async {
        // App is pumped with zero network/auth/GPS mocks, fully offline
        await pumpNavigationApp(tester);

        final router = ProviderScope.containerOf(
          tester.element(find.byType(GramTransitApp)),
        ).read(routerProvider);

        router.go('/journeys?from=stop_1&to=stop_2');
        await tester.pumpAndSettle();

        expect(find.byType(JourneySearchScreen), findsOneWidget);
        expect(find.byType(ScheduledJourneyCard), findsWidgets);
      },
    );
  });
}
