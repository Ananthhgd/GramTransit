import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_colors.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_radius.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_typography.dart';

/// Provides the GramTransit [ThemeData] instances for light and dark modes.
///
/// Seed: [GtColors.brandSeed] (deep green #1E6B3C).
/// Only components actually used by Foundation A are customised here.
abstract final class GtTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: GtColors.brandSeed,
      brightness: brightness,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: GtTypography.textTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: GtRadius.cardRadius),
      ),
    );
  }
}
