import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/theme/gt_theme.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';
import 'package:gramtransit_passenger/core/time/time_providers.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

/// Test double for [TimetableRepository] in Browse tests.
class FakeBrowseTimetableRepository implements TimetableRepository {
  FakeBrowseTimetableRepository({this.timetable, this.error, this.completer});

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

/// Creates a standard test [Timetable] fixture for Browse tests.
Timetable createBrowseTestTimetable({
  bool isSampleData = true,
  List<TransitStop>? stops,
  List<TransitRoute>? routes,
  List<ScheduledTrip>? trips,
}) {
  final defaultStops =
      stops ??
      [
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
          name: LocalizedText(english: 'Market Square'),
        ),
        TransitStop(
          id: StopId('stop_unused'),
          name: LocalizedText(english: 'Unused Stop'),
        ),
      ];

  final defaultRoutes =
      routes ??
      [
        TransitRoute(
          id: RouteId('route_1'),
          shortName: LocalizedText(english: '101'),
          longName: LocalizedText(english: 'City Center - North Station'),
        ),
        TransitRoute(
          id: RouteId('route_2'),
          shortName: LocalizedText(english: '102'),
          longName: LocalizedText(english: 'City Center - Market Square'),
        ),
        TransitRoute(
          id: RouteId('route_unused'),
          shortName: LocalizedText(english: '999'),
          longName: LocalizedText(english: 'Unused Route'),
        ),
      ];

  final defaultTrips =
      trips ??
      [
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
        ScheduledTrip(
          id: TripId('trip_2'),
          routeId: RouteId('route_2'),
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
              arrivalTime: ServiceTime(hour: 9, minute: 0),
              departureTime: ServiceTime(hour: 9, minute: 5),
            ),
            StopTime(
              stopId: StopId('stop_3'),
              arrivalTime: ServiceTime(hour: 9, minute: 25),
              departureTime: ServiceTime(hour: 9, minute: 30),
            ),
          ],
        ),
      ];

  return Timetable(
    info: TimetableInfo(datasetVersion: '1.0.0', isSampleData: isSampleData),
    stops: defaultStops,
    routes: defaultRoutes,
    trips: defaultTrips,
  );
}

/// Pumps a browse test widget tree with consistent localization, theme, and providers.
Future<void> pumpBrowseTest(
  WidgetTester tester, {
  required Widget child,
  List<dynamic> overrides = const [],
  DateTime? now,
  Size surfaceSize = const Size(390, 844),
  double textScaleFactor = 1.0,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  tester.view.physicalSize = surfaceSize * tester.view.devicePixelRatio;
  addTearDown(() => tester.view.resetPhysicalSize());

  // Default test time: Monday 2026-10-19 07:30 UTC
  final effectiveNow = now ?? DateTime.utc(2026, 10, 19, 7, 30);

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
            size: surfaceSize,
            textScaler: TextScaler.linear(textScaleFactor),
          ),
          child: child,
        ),
      ),
    ),
  );
  await tester.pump();
}
