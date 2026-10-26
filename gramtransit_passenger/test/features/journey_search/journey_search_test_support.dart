import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/theme/gt_theme.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';
import 'package:gramtransit_passenger/core/time/time_providers.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/journey_search_screen.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/scheduled_journey.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

/// Minimal fake [TimetableRepository] for Journey Search tests.
class FakeTimetableRepository implements TimetableRepository {
  FakeTimetableRepository({this.timetable, this.error, this.completer});

  Timetable? timetable;
  Object? error;
  Completer<Timetable>? completer;
  int loadCount = 0;

  @override
  Future<Timetable> loadTimetable() async {
    loadCount++;
    if (completer != null) {
      return completer!.future;
    }
    if (error != null) {
      throw error!;
    }
    return timetable!;
  }
}

/// Creates a standard test [Timetable] fixture with rich stop and trip configurations.
Timetable createJourneyTestTimetable({
  bool isSampleData = true,
  List<TransitStop>? stops,
  List<TransitRoute>? routes,
  List<ScheduledTrip>? trips,
}) {
  final defaultStops =
      stops ??
      [
        TransitStop(
          id: StopId('stop_alpha_1'),
          name: LocalizedText(english: 'Alpha Central'),
        ),
        // Duplicate name stop to test identity by StopId
        TransitStop(
          id: StopId('stop_alpha_2'),
          name: LocalizedText(english: 'Alpha Central'),
        ),
        TransitStop(
          id: StopId('stop_beta'),
          name: LocalizedText(english: 'Beta Junction'),
        ),
        TransitStop(
          id: StopId('stop_central'),
          name: LocalizedText(english: 'Central Station'),
        ),
      ];

  final defaultRoutes =
      routes ??
      [
        TransitRoute(
          id: RouteId('route_101'),
          shortName: LocalizedText(english: '101'),
          longName: LocalizedText(english: 'Alpha to Central'),
        ),
        TransitRoute(
          id: RouteId('route_202'),
          shortName: LocalizedText(english: '202'),
          longName: LocalizedText(english: 'Express Loop'),
        ),
      ];

  final defaultTrips =
      trips ??
      [
        // Regular trip: 08:00 to 08:30 (Duration 30 min)
        ScheduledTrip(
          id: TripId('trip_morning'),
          routeId: RouteId('route_101'),
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
              stopId: StopId('stop_alpha_1'),
              arrivalTime: ServiceTime(hour: 8, minute: 0),
              departureTime: ServiceTime(hour: 8, minute: 0),
            ),
            StopTime(
              stopId: StopId('stop_central'),
              arrivalTime: ServiceTime(hour: 8, minute: 30),
              departureTime: ServiceTime(hour: 8, minute: 30),
            ),
          ],
        ),
        // Zero-duration trip: 09:00 to 09:00 (scheduledDuration == Duration.zero)
        ScheduledTrip(
          id: TripId('trip_zero_duration'),
          routeId: RouteId('route_202'),
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
              stopId: StopId('stop_alpha_1'),
              arrivalTime: ServiceTime(hour: 9, minute: 0),
              departureTime: ServiceTime(hour: 9, minute: 0),
            ),
            StopTime(
              stopId: StopId('stop_beta'),
              arrivalTime: ServiceTime(hour: 9, minute: 0),
              departureTime: ServiceTime(hour: 9, minute: 0),
            ),
          ],
        ),
        // Next-day trip: 23:45 to 24:15 (00:15 next calendar day)
        ScheduledTrip(
          id: TripId('trip_next_day'),
          routeId: RouteId('route_101'),
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
              stopId: StopId('stop_alpha_1'),
              arrivalTime: ServiceTime(hour: 23, minute: 45),
              departureTime: ServiceTime(hour: 23, minute: 45),
            ),
            StopTime(
              stopId: StopId('stop_central'),
              arrivalTime: ServiceTime(hour: 24, minute: 15),
              departureTime: ServiceTime(hour: 24, minute: 15),
            ),
          ],
        ),
      ];

  return Timetable(
    info: TimetableInfo(datasetVersion: 'test-v1', isSampleData: isSampleData),
    stops: defaultStops,
    routes: defaultRoutes,
    trips: defaultTrips,
  );
}

/// Pumps [child] or [JourneySearchScreen] with test overrides.
Future<void> pumpJourneySearchTest(
  WidgetTester tester, {
  Widget? child,
  StopId? initialBoardingStopId,
  StopId? initialAlightingStopId,
  ValueChanged<ScheduledJourney>? onJourneySelected,
  List<dynamic> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  double textScaleFactor = 1.0,
  DateTime? fixedNow,
  Size? surfaceSize,
}) async {
  if (surfaceSize != null) {
    tester.view.physicalSize = surfaceSize * tester.view.devicePixelRatio;
    addTearDown(() {
      tester.view.resetPhysicalSize();
    });
  }

  // Default Monday morning 2026-01-05 07:30 before morning trips
  final effectiveNow = fixedNow ?? DateTime(2026, 1, 5, 7, 30);

  final defaultOverrides = [
    minuteTickerProvider.overrideWith(
      (ref) => Stream<DateTime>.value(effectiveNow),
    ),
    ...overrides,
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: defaultOverrides.cast(),
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: GtTheme.light(),
        darkTheme: GtTheme.dark(),
        themeMode: themeMode,
        home: MediaQuery(
          data: MediaQueryData(
            size: surfaceSize ?? Size.zero,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child:
              child ??
              JourneySearchScreen(
                initialBoardingStopId: initialBoardingStopId,
                initialAlightingStopId: initialAlightingStopId,
                onJourneySelected: onJourneySelected,
              ),
        ),
      ),
    ),
  );
  await tester.pump();
}
