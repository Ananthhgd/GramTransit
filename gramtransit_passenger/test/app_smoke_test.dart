import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/app/gramtransit_app.dart';

void main() {
  group('Foundation A — smoke tests', () {
    testWidgets('app starts under ProviderScope without error', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: GramTransitApp()));
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('home screen shows localized welcome content', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: GramTransitApp()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome to GramTransit'), findsOneWidget);
      expect(find.text('Bus timings for your village routes'), findsOneWidget);
    });

    testWidgets('home and more navigation destinations are present', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: GramTransitApp()));
      await tester.pumpAndSettle();

      // NavigationBar destinations
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('More'), findsAtLeastNWidgets(1));
    });

    testWidgets('navigating More → Settings displays the theme selector', (
      tester,
    ) async {
      await tester.pumpWidget(const ProviderScope(child: GramTransitApp()));
      await tester.pumpAndSettle();

      // Tap the More destination in the bottom NavigationBar.
      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();

      // Tap the Settings list tile.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // All three theme mode segments should be visible.
      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });
  });
}
