import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';
import 'package:gramtransit_passenger/features/settings/data/settings_repository.dart';

void main() {
  SettingsRepository makeRepo({Map<String, String>? initial}) {
    return SettingsRepository(InMemoryKeyValueStore(initial: initial));
  }

  group('SettingsRepository.readThemeMode', () {
    test('returns ThemeMode.system when key is missing', () {
      final repo = makeRepo();
      expect(repo.readThemeMode(), ThemeMode.system);
    });

    test('returns ThemeMode.system for stored "system"', () {
      final repo = makeRepo(initial: {'gt.settings.theme_mode': 'system'});
      expect(repo.readThemeMode(), ThemeMode.system);
    });

    test('returns ThemeMode.light for stored "light"', () {
      final repo = makeRepo(initial: {'gt.settings.theme_mode': 'light'});
      expect(repo.readThemeMode(), ThemeMode.light);
    });

    test('returns ThemeMode.dark for stored "dark"', () {
      final repo = makeRepo(initial: {'gt.settings.theme_mode': 'dark'});
      expect(repo.readThemeMode(), ThemeMode.dark);
    });

    test('returns ThemeMode.system for unknown stored value', () {
      final repo = makeRepo(initial: {'gt.settings.theme_mode': 'unknown'});
      expect(repo.readThemeMode(), ThemeMode.system);
    });

    test('returns ThemeMode.system for empty string stored value', () {
      final repo = makeRepo(initial: {'gt.settings.theme_mode': ''});
      expect(repo.readThemeMode(), ThemeMode.system);
    });
  });

  group('SettingsRepository.saveThemeMode', () {
    test('saves "system" for ThemeMode.system', () async {
      final store = InMemoryKeyValueStore();
      final repo = SettingsRepository(store);
      await repo.saveThemeMode(ThemeMode.system);
      expect(store.getString('gt.settings.theme_mode'), equals('system'));
    });

    test('saves "light" for ThemeMode.light', () async {
      final store = InMemoryKeyValueStore();
      final repo = SettingsRepository(store);
      await repo.saveThemeMode(ThemeMode.light);
      expect(store.getString('gt.settings.theme_mode'), equals('light'));
    });

    test('saves "dark" for ThemeMode.dark', () async {
      final store = InMemoryKeyValueStore();
      final repo = SettingsRepository(store);
      await repo.saveThemeMode(ThemeMode.dark);
      expect(store.getString('gt.settings.theme_mode'), equals('dark'));
    });

    test('save then read round-trips correctly', () async {
      final store = InMemoryKeyValueStore();
      final repo = SettingsRepository(store);

      for (final mode in ThemeMode.values) {
        await repo.saveThemeMode(mode);
        expect(repo.readThemeMode(), equals(mode));
      }
    });
  });
}
