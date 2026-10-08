import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the application-wide [ThemeMode].
///
/// Uses the Riverpod 3 [Notifier] API — no code generation.
///
/// The theme selection is intentionally kept in memory only.
/// Restarting the application always returns to [ThemeMode.system].
/// Persistence will be introduced in Foundation B.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Updates the active [ThemeMode]. The change is applied immediately
  /// throughout the application.
  void setThemeMode(ThemeMode mode) => state = mode;
}

/// Application-wide provider for [ThemeModeController].
///
/// Not auto-disposed — lives for the lifetime of the [ProviderScope].
final themeModeControllerProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
