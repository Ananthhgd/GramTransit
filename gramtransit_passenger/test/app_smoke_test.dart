import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';
import 'package:gramtransit_passenger/app/gramtransit_app.dart';

/// Pumps [GramTransitApp] with required Foundation B provider overrides.
///
/// [storeOverrides] can be used to seed initial values (e.g. a stored theme).
Future<void> pumpApp(
  WidgetTester tester, {
  Map<String, String>? storeOverrides,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        keyValueStoreProvider.overrideWithValue(
          InMemoryKeyValueStore(initial: storeOverrides),
        ),
      ],
      child: const GramTransitApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Foundation A — smoke tests (preserved)', () {
    testWidgets('app starts under ProviderScope without error', (tester) async {
      await pumpApp(tester);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('home screen shows localized welcome content', (tester) async {
      await pumpApp(tester);
      expect(find.text('Welcome to GramTransit'), findsOneWidget);
      expect(find.text('Bus timings for your village routes'), findsOneWidget);
    });

    testWidgets('home and more navigation destinations are present', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('More'), findsAtLeastNWidgets(1));
    });

    testWidgets('navigating More → Settings displays the theme selector', (
      tester,
    ) async {
      await pumpApp(tester);

      await tester.tap(find.text('More').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('System'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
    });
  });

  group('Foundation B — persistence smoke tests', () {
    testWidgets(
      'seeded dark preference produces dark ThemeMode on first frame',
      (tester) async {
        await pumpApp(
          tester,
          storeOverrides: {'gt.settings.theme_mode': 'dark'},
        );

        // GramTransitApp watches themeModeControllerProvider.
        // With a dark-seeded store, ThemeMode.dark must be active.
        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.themeMode, equals(ThemeMode.dark));
      },
    );

    testWidgets(
      'seeded light preference produces light ThemeMode on first frame',
      (tester) async {
        await pumpApp(
          tester,
          storeOverrides: {'gt.settings.theme_mode': 'light'},
        );

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.themeMode, equals(ThemeMode.light));
      },
    );

    testWidgets(
      'no stored preference produces system ThemeMode on first frame',
      (tester) async {
        await pumpApp(tester);

        final materialApp = tester.widget<MaterialApp>(
          find.byType(MaterialApp),
        );
        expect(materialApp.themeMode, equals(ThemeMode.system));
      },
    );

    testWidgets(
      'changing theme persists the expected stable string to storage',
      (tester) async {
        final store = InMemoryKeyValueStore();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [keyValueStoreProvider.overrideWithValue(store)],
            child: const GramTransitApp(),
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to Settings.
        await tester.tap(find.text('More').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Settings'));
        await tester.pumpAndSettle();

        // Tap the "Dark" segment.
        await tester.tap(find.text('Dark'));
        await tester.pumpAndSettle();

        expect(store.getString('gt.settings.theme_mode'), equals('dark'));
      },
    );
  });
}
