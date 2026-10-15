import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/core/design_system/theme/gt_theme.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';
import 'package:gramtransit_passenger/features/transit/domain/timetable_repository.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

/// Test repository for trip_details unit and widget tests.
class FakeTripDetailsTimetableRepository implements TimetableRepository {
  FakeTripDetailsTimetableRepository({
    this.timetable,
    this.error,
    this.completer,
  });

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

/// Fixture generator for trip_details tests.
Timetable createTripDetailsTestTimetable({
  List<TransitStop>? stops,
  List<TransitRoute>? routes,
  List<ScheduledTrip>? trips,
  bool isSampleData = false,
}) {
  final defaultStops =
      stops ??
      [
        TransitStop(
          id: StopId('stop_1'),
          name: LocalizedText(english: 'City Center', kannada: 'ನಗರ ಕೇಂದ್ರ'),
        ),
        TransitStop(
          id: StopId('stop_2'),
          name: LocalizedText(
            english: 'Market Square',
            kannada: 'ಮಾರುಕಟ್ಟೆ ಚೌಕ',
          ),
        ),
        TransitStop(
          id: StopId('stop_3'),
          name: LocalizedText(
            english: 'North Station',
            kannada: 'ಉತ್ತರ ನಿಲ್ದಾಣ',
          ),
        ),
      ];

  final defaultRoutes =
      routes ??
      [
        TransitRoute(
          id: RouteId('route_1'),
          shortName: LocalizedText(english: '101'),
          longName: LocalizedText(english: 'City Center to North Station'),
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
              arrivalTime: ServiceTime(hour: 8, minute: 15),
              departureTime: ServiceTime(hour: 8, minute: 15),
            ),
            StopTime(
              stopId: StopId('stop_3'),
              arrivalTime: ServiceTime(hour: 8, minute: 30),
              departureTime: ServiceTime(hour: 8, minute: 35),
            ),
          ],
        ),
      ];

  return Timetable(
    info: TimetableInfo(
      datasetVersion: 'test-trip-v1',
      isSampleData: isSampleData,
    ),
    stops: defaultStops,
    routes: defaultRoutes,
    trips: defaultTrips,
  );
}

/// Pump helper for trip_details widget tests.
Future<void> pumpTripDetailsTest(
  WidgetTester tester, {
  Widget? child,
  GoRouter? router,
  List<dynamic> overrides = const [],
  ThemeMode themeMode = ThemeMode.light,
  double textScaleFactor = 1.0,
  Locale locale = const Locale('en'),
  Size surfaceSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = surfaceSize * tester.view.devicePixelRatio;
  addTearDown(() {
    tester.view.resetPhysicalSize();
  });

  final Widget app;
  if (router != null) {
    app = MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: GtTheme.light(),
      darkTheme: GtTheme.dark(),
      themeMode: themeMode,
    );
  } else {
    app = MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      theme: GtTheme.light(),
      darkTheme: GtTheme.dark(),
      themeMode: themeMode,
      home: MediaQuery(
        data: MediaQueryData(
          textScaler: TextScaler.linear(textScaleFactor),
          size: surfaceSize,
        ),
        child: child!,
      ),
    );
  }

  await tester.pumpWidget(
    ProviderScope(overrides: overrides.cast(), child: app),
  );
  await tester.pump();
}
