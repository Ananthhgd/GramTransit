import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';
import 'package:gramtransit_passenger/features/settings/application/theme_mode_controller.dart';

/// Creates a [ProviderContainer] with the given [store] as the key-value store.
ProviderContainer makeContainer({required InMemoryKeyValueStore store}) {
  return ProviderContainer(
    overrides: [keyValueStoreProvider.overrideWithValue(store)],
  );
}

void main() {
  group('ThemeModeController — initial state from persistence', () {
    test('defaults to ThemeMode.system when no preference is stored', () {
      final container = makeContainer(store: InMemoryKeyValueStore());
      addTearDown(container.dispose);

      expect(
        container.read(themeModeControllerProvider),
        equals(ThemeMode.system),
      );
    });

    test('reads seeded "dark" preference as ThemeMode.dark on build', () {
      final container = makeContainer(
        store: InMemoryKeyValueStore(
          initial: {'gt.settings.theme_mode': 'dark'},
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(themeModeControllerProvider),
        equals(ThemeMode.dark),
      );
    });

    test('reads seeded "light" preference as ThemeMode.light on build', () {
      final container = makeContainer(
        store: InMemoryKeyValueStore(
          initial: {'gt.settings.theme_mode': 'light'},
        ),
      );
      addTearDown(container.dispose);

      expect(
        container.read(themeModeControllerProvider),
        equals(ThemeMode.light),
      );
    });
  });

  group('ThemeModeController — setThemeMode', () {
    test('updates state to the new mode', () async {
      final container = makeContainer(store: InMemoryKeyValueStore());
      addTearDown(container.dispose);

      await container
          .read(themeModeControllerProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(
        container.read(themeModeControllerProvider),
        equals(ThemeMode.dark),
      );
    });

    test('writes stable string to storage', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      await container
          .read(themeModeControllerProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(store.getString('gt.settings.theme_mode'), equals('light'));
    });

    test('selecting current mode does not write to storage', () async {
      final store = InMemoryKeyValueStore(
        initial: {'gt.settings.theme_mode': 'dark'},
      );
      final container = makeContainer(store: store);
      addTearDown(container.dispose);

      // First read to ensure state is dark.
      expect(container.read(themeModeControllerProvider), ThemeMode.dark);

      // Clobber the stored value to detect if a write happens.
      await store.setString('gt.settings.theme_mode', 'SENTINEL');

      // Re-selecting dark — should be a no-op.
      await container
          .read(themeModeControllerProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      // Sentinel must remain untouched.
      expect(store.getString('gt.settings.theme_mode'), equals('SENTINEL'));
    });

    test(
      'failing store keeps session state and rethrows StorageFailure',
      () async {
        final container = ProviderContainer(
          overrides: [
            keyValueStoreProvider.overrideWithValue(
              const FailingKeyValueStore(),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Also provide a working settingsRepository so build() can read (returns system).
        // FailingKeyValueStore.getString returns null → system default.
        expect(container.read(themeModeControllerProvider), ThemeMode.system);

        // setThemeMode should update state immediately then rethrow StorageFailure.
        await expectLater(
          container
              .read(themeModeControllerProvider.notifier)
              .setThemeMode(ThemeMode.light),
          throwsA(isA<StorageFailure>()),
        );

        // State must be updated (not rolled back).
        expect(container.read(themeModeControllerProvider), ThemeMode.light);
      },
    );
  });
}
