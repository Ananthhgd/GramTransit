import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_trip_card.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/trip_occurrence.dart';

import '../home_test_support.dart';

void main() {
  group('UpcomingTripCard', () {
    late TripOccurrence sampleOccurrence;

    setUp(() {
      sampleOccurrence = TripOccurrence(
        tripId: TripId('trip_1'),
        routeId: RouteId('route_1'),
        routeShortName: LocalizedText(english: '1A'),
        routeLongName: LocalizedText(english: 'City Center - North Station'),
        destinationName: LocalizedText(english: 'North Station'),
        scheduledDeparture: DateTime(2026, 10, 14, 8, 5),
        tripEnd: DateTime(2026, 10, 14, 8, 25),
      );
    });

    testWidgets(
      'renders primary clock time, destination, and route in current departure mode',
      (tester) async {
        await pumpHomeTest(
          tester,
          child: UpcomingTripCard(
            occurrence: sampleOccurrence,
            showDate: false,
          ),
        );

        // Primary: scheduled departure clock time
        expect(find.text('8:05 AM'), findsOneWidget);

        // Secondary: "To {destination}"
        expect(find.text('To North Station'), findsOneWidget);

        // Tertiary: "Route {shortName} · {longName}"
        expect(
          find.text('Route 1A · City Center - North Station'),
          findsOneWidget,
        );

        // No live / ETA semantics
        expect(
          find.textContaining(RegExp('live', caseSensitive: false)),
          findsNothing,
        );
        expect(
          find.textContaining(RegExp('eta', caseSensitive: false)),
          findsNothing,
        );
        expect(
          find.textContaining(RegExp('delayed', caseSensitive: false)),
          findsNothing,
        );
        expect(
          find.textContaining(RegExp('on time', caseSensitive: false)),
          findsNothing,
        );
        expect(
          find.textContaining(RegExp('early', caseSensitive: false)),
          findsNothing,
        );
      },
    );

    testWidgets('renders date + scheduled clock time when showDate is true', (
      tester,
    ) async {
      await pumpHomeTest(
        tester,
        child: UpcomingTripCard(occurrence: sampleOccurrence, showDate: true),
      );

      // Dated primary: date + clock time
      expect(find.text('Wed, Oct 14 · 8:05 AM'), findsOneWidget);
      expect(find.text('To North Station'), findsOneWidget);
      expect(
        find.text('Route 1A · City Center - North Station'),
        findsOneWidget,
      );
    });

    testWidgets(
      'card is strictly non-interactive (no tap action or chevrons)',
      (tester) async {
        await pumpHomeTest(
          tester,
          child: UpcomingTripCard(occurrence: sampleOccurrence),
        );

        // Verify no InkWell or GestureDetector on the card
        expect(
          find.descendant(
            of: find.byType(UpcomingTripCard),
            matching: find.byType(InkWell),
          ),
          findsNothing,
        );

        // Verify no navigation chevrons
        expect(find.byIcon(Icons.chevron_right), findsNothing);
        expect(find.byIcon(Icons.arrow_forward_ios), findsNothing);
        expect(find.byIcon(Icons.arrow_forward), findsNothing);
      },
    );
  });
}
