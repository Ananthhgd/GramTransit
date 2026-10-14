import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/features/home/presentation/home_display_format.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';

void main() {
  group('HomeDisplayFormat', () {
    testWidgets(
      'formatScheduledTime formats 12-hour and 24-hour deterministically based on MediaQuery',
      (tester) async {
        final dateTime = DateTime(2026, 10, 14, 8, 5);

        // 12-hour format test
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(alwaysUse24HourFormat: false),
              child: Builder(
                builder: (context) {
                  final formatted = formatScheduledTime(context, dateTime);
                  return Text(formatted);
                },
              ),
            ),
          ),
        );
        expect(find.text('8:05 AM'), findsOneWidget);

        // 24-hour format test
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(alwaysUse24HourFormat: true),
              child: Builder(
                builder: (context) {
                  final formatted = formatScheduledTime(context, dateTime);
                  return Text(formatted);
                },
              ),
            ),
          ),
        );
        expect(find.text('08:05'), findsOneWidget);
      },
    );

    testWidgets('formatDepartureDate formats localized date skeleton', (
      tester,
    ) async {
      final dateTime = DateTime(2026, 10, 14, 8, 5); // Wednesday

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          home: Builder(
            builder: (context) {
              final formatted = formatDepartureDate(context, dateTime);
              return Text(formatted);
            },
          ),
        ),
      );

      expect(find.text('Wed, Oct 14'), findsOneWidget);
    });

    testWidgets(
      'formatNextLaterDeparture combines localized date and scheduled clock time',
      (tester) async {
        final dateTime = DateTime(2026, 10, 14, 8, 5);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('en'),
            home: MediaQuery(
              data: const MediaQueryData(alwaysUse24HourFormat: false),
              child: Builder(
                builder: (context) {
                  final formatted = formatNextLaterDeparture(context, dateTime);
                  return Text(formatted);
                },
              ),
            ),
          ),
        );

        expect(find.text('Wed, Oct 14 · 8:05 AM'), findsOneWidget);
      },
    );

    test('resolveLocalizedText returns English for Phase 1', () {
      final text = LocalizedText(english: 'City Center', kannada: 'ನಗರ ಕೇಂದ್ರ');
      expect(resolveLocalizedText(text), equals('City Center'));
    });
  });
}
