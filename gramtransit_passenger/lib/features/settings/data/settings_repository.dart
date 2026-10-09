import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/storage/key_value_store.dart';
import 'package:gramtransit_passenger/core/storage/storage_providers.dart';

/// Storage key for the persisted theme mode preference.
///
/// Owned by the settings feature. Kept as a private constant to prevent
/// accidental external references.
const _kThemeModeKey = 'gt.settings.theme_mode';

/// Manages reading and writing settings preferences to [KeyValueStore].
///
/// Does NOT own any Riverpod state — state ownership belongs to
/// [ThemeModeController] in the application layer.
final class SettingsRepository {
  const SettingsRepository(this._store);

  final KeyValueStore _store;

  /// Returns the persisted [ThemeMode].
  ///
  /// - `"system"` → [ThemeMode.system]
  /// - `"light"` → [ThemeMode.light]
  /// - `"dark"` → [ThemeMode.dark]
  /// - missing / unknown / invalid → [ThemeMode.system] (safe default)
  ///
  /// Invalid stored values are silently ignored (not overwritten) so that a
  /// future schema migration can decide what to do with them.
  ThemeMode readThemeMode() {
    final stored = _store.getString(_kThemeModeKey);
    return switch (stored) {
      'system' => ThemeMode.system,
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  /// Persists [mode] to storage.
  ///
  /// Uses stable string constants — does NOT rely on [ThemeMode.name] so that
  /// renaming the enum value in a future Flutter version cannot silently break
  /// stored preferences.
  ///
  /// Throws [StorageFailure] if the write fails (propagated from
  /// [KeyValueStore]).
  Future<void> saveThemeMode(ThemeMode mode) {
    final value = switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };
    return _store.setString(_kThemeModeKey, value);
  }
}

/// Provider for [SettingsRepository].
///
/// Reads [keyValueStoreProvider] — bootstrap must have initialised it first.
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.read(keyValueStoreProvider)),
  name: 'settingsRepositoryProvider',
);
