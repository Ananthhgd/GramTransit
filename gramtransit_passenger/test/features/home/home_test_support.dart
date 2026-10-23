import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/design_system/theme/gt_theme.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';
import 'package:gramtransit_passenger/core/time/time_providers.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_screen.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

/// Minimal fake [TimetableRepository] for P5 Home tests.
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

/// Creates a standard test [Timetable] fixture.
Timetable createTestTimetable({
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
      ];

  final defaultRoutes =
      routes ??
      [
        TransitRoute(
          id: RouteId('route_1'),
          shortName: LocalizedText(english: '1A'),
          longName: LocalizedText(english: 'City Center - North Station'),
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
              arrivalTime: ServiceTime(hour: 8, minute: 20),
              departureTime: ServiceTime(hour: 8, minute: 25),
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

/// Pumps [child] or [HomeScreen] with P5 test overrides and configuration.
Future<void> pumpHomeTest(
  WidgetTester tester, {
  Widget? child,
  ValueChanged<StopId?>? onSearchTap,
  VoidCallback? onAllStopsTap,
  VoidCallback? onAllRoutesTap,
  List<dynamic> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  double textScaleFactor = 1.0,
  DateTime? fixedNow,
}) async {
  final effectiveNow = fixedNow ?? DateTime(2026, 10, 14, 7, 50);

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
          data: MediaQueryData(textScaler: TextScaler.linear(textScaleFactor)),
          child: child != null
              ? (child is Scaffold
                    ? child
                    : Scaffold(
                        body: SafeArea(
                          child: SingleChildScrollView(child: child),
                        ),
                      ))
              : HomeScreen(
                  onSearchTap: onSearchTap,
                  onAllStopsTap: onAllStopsTap,
                  onAllRoutesTap: onAllRoutesTap,
                ),
        ),
      ),
    ),
  );
  await tester.pump();
}
