import 'package:flutter/material.dart';

/// GramTransit typography tokens.
///
/// Foundation A uses the platform font — no custom typeface is bundled.
/// Custom fonts will be introduced in a later phase.
///
/// Feature widgets should use [Theme.of(context).textTheme] directly
/// rather than calling methods on this class.
abstract final class GtTypography {
  /// Returns the Material 3 default [TextTheme], applied to both light and
  /// dark [ThemeData] via [GtTheme]. Acts as a hook for future font changes.
  static TextTheme textTheme() => const TextTheme();
}
