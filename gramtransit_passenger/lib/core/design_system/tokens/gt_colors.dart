import 'package:flutter/material.dart';

/// GramTransit colour tokens.
///
/// Feature widgets must NOT use these directly.
/// They should use [Theme.of(context).colorScheme] instead.
abstract final class GtColors {
  /// Brand seed colour — deep green (#1E6B3C).
  /// Used exclusively by [GtTheme] to generate [ColorScheme] instances.
  static const Color brandSeed = Color(0xFF1E6B3C);
}
