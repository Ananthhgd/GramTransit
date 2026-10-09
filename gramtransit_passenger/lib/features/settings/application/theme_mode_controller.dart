import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/logging/logging_providers.dart';
import 'package:gramtransit_passenger/features/settings/data/settings_repository.dart';

/// Controls the application-wide [ThemeMode].
///
/// Uses the Riverpod 3 [Notifier] API — no code generation.
/// Remains a synchronous [Notifier]; NOT converted to [AsyncNotifier].
///
/// Persistence:
/// - [build] reads the stored preference synchronously via [SettingsRepository].
/// - [setThemeMode] updates state immediately then persists asynchronously.
/// - If persistence fails, the new mode is kept for the session, a warning is
///   logged, and [StorageFailure] is rethrown so the presentation layer can
///   notify the user.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // ref.read is appropriate here: SettingsRepository is a stable dependency
    // that does not itself expose reactive state.
    return ref.read(settingsRepositoryProvider).readThemeMode();
  }

  /// Updates the active [ThemeMode].
  ///
  /// - If [mode] equals the current [state], this is a no-op (no write).
  /// - State is updated immediately; persistence follows asynchronously.
  /// - On persistence failure:
  ///   - State is kept (no rollback).
  ///   - A warning is logged.
  ///   - [StorageFailure] is rethrown for the presentation layer.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (state == mode) return;

    state = mode;

    try {
      await ref.read(settingsRepositoryProvider).saveThemeMode(mode);
    } on StorageFailure catch (failure, st) {
      ref
          .read(appLoggerProvider)
          .warning(
            'ThemeModeController: failed to persist theme mode',
            error: failure,
            stackTrace: st,
          );
      rethrow;
    }
  }
}

/// Application-wide provider for [ThemeModeController].
///
/// Not auto-disposed — lives for the lifetime of the [ProviderContainer].
final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
