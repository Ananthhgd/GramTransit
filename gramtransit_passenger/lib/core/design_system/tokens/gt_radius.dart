import 'package:flutter/material.dart';

/// GramTransit border-radius tokens.
abstract final class GtRadius {
  /// 12 dp — used for Card components.
  static const double md = 12;

  /// 999 dp — pill / fully-rounded shapes (e.g., search entry placeholder).
  static const double full = 999;

  /// Convenience [BorderRadius] for cards.
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(md));

  /// Convenience [BorderRadius] for pill shapes.
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(full),
  );
}
