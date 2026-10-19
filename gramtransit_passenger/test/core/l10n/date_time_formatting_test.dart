import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gramtransit_passenger/core/l10n/date_time_formatting.dart';

void main() {
  group('DateTimeFormatting', () {
    testWidgets('12-hour clock formatting respects MediaQuery', (tester) async {
      const timeOfDay = TimeOfDay(hour: 8, minute: 5);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: MediaQuery(
            data: const MediaQueryData(alwaysUse24HourFormat: false),
            child: Builder(
              builder: (context) {
                final formatted = formatClockTime(context, timeOfDay);
                return Text(formatted);
              },
            ),
          ),
        ),
      );

      expect(find.text('8:05 AM'), findsOneWidget);
    });

    testWidgets('24-hour clock formatting respects MediaQuery', (tester) async {
      const timeOfDay = TimeOfDay(hour: 8, minute: 5);

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: MediaQuery(
            data: const MediaQueryData(alwaysUse24HourFormat: true),
            child: Builder(
              builder: (context) {
                final formatted = formatClockTime(context, timeOfDay);
                return Text(formatted);
              },
            ),
          ),
        ),
      );

      expect(find.text('08:05'), findsOneWidget);
    });

    testWidgets('deterministic MMMEd fixed-date formatting', (tester) async {
      final dateTime = DateTime(2026, 10, 14, 8, 5); // Wednesday

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final formatted = formatShortDate(context, dateTime);
              return Text(formatted);
            },
          ),
        ),
      );

      expect(find.text('Wed, Oct 14'), findsOneWidget);
    });

    testWidgets(
      'weekdays 1 through 7 produce Mon through Sun under en locale',
      (tester) async {
        final expectedShortDays = [
          'Mon',
          'Tue',
          'Wed',
          'Thu',
          'Fri',
          'Sat',
          'Sun',
        ];

        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('en')],
            locale: const Locale('en'),
            home: Builder(
              builder: (context) {
                final formattedDays = [
                  for (int d = 1; d <= 7; d++) formatShortWeekday(context, d),
                ];
                return Column(
                  children: [for (final day in formattedDays) Text(day)],
                );
              },
            ),
          ),
        );

        for (final day in expectedShortDays) {
          expect(find.text(day), findsOneWidget);
        }
      },
    );

    testWidgets(
      'formatShortWeekday throws ArgumentError for invalid weekdays',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('en')],
            locale: const Locale('en'),
            home: Builder(
              builder: (context) {
                expect(
                  () => formatShortWeekday(context, 0),
                  throwsA(isA<ArgumentError>()),
                );
                expect(
                  () => formatShortWeekday(context, 8),
                  throwsA(isA<ArgumentError>()),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );

    testWidgets('formatShortWeekdays formats Monday-only correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final result = formatShortWeekdays(context, [DateTime.monday]);
              expect(result, equals(['Mon']));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('formatShortWeekdays formats Sunday-only correctly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final result = formatShortWeekdays(context, [DateTime.sunday]);
              expect(result, equals(['Sun']));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('formatShortWeekdays formats multiple weekdays', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final result = formatShortWeekdays(context, [
                DateTime.monday,
                DateTime.wednesday,
                DateTime.friday,
              ]);
              expect(result, equals(['Mon', 'Wed', 'Fri']));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets(
      'formatShortWeekdays preserves Monday-first order when input is out of order and deduplicates',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('en')],
            locale: const Locale('en'),
            home: Builder(
              builder: (context) {
                final result = formatShortWeekdays(context, [
                  DateTime.sunday,
                  DateTime.friday,
                  DateTime.monday,
                  DateTime.wednesday,
                  DateTime.friday,
                ]);
                expect(result, equals(['Mon', 'Wed', 'Fri', 'Sun']));
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );

    testWidgets(
      'formatShortWeekdays uses existing localized weekday abbreviations for all 7 days',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('en')],
            locale: const Locale('en'),
            home: Builder(
              builder: (context) {
                final allDays = [
                  DateTime.monday,
                  DateTime.tuesday,
                  DateTime.wednesday,
                  DateTime.thursday,
                  DateTime.friday,
                  DateTime.saturday,
                  DateTime.sunday,
                ];
                final result = formatShortWeekdays(context, allDays);
                expect(
                  result,
                  equals(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );

    testWidgets('formatShortWeekdays handles empty input list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final result = formatShortWeekdays(context, []);
              expect(result, isEmpty);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets(
      'formatShortWeekdays throws ArgumentError for invalid weekdays',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('en')],
            locale: const Locale('en'),
            home: Builder(
              builder: (context) {
                expect(
                  () => formatShortWeekdays(context, [0]),
                  throwsA(isA<ArgumentError>()),
                );
                expect(
                  () => formatShortWeekdays(context, [DateTime.monday, 8]),
                  throwsA(isA<ArgumentError>()),
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        );
      },
    );
  });
}
