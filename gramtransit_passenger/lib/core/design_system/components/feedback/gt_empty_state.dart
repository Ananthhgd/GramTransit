import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';

/// A generic empty-state widget using design-system tokens.
///
/// Provides consistent empty-state presentation across features.
/// Empty collection handling is the responsibility of the feature widget,
/// not of [AsyncValueView].
///
/// Accessibility: the [icon], [title], and [message] are grouped under a
/// single [Semantics] container to be read as a coherent block.
class GtEmptyState extends StatelessWidget {
  const GtEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Icon displayed above the title.
  final IconData icon;

  /// Short title describing the empty state.
  final String title;

  /// Optional longer explanatory message below the title.
  final String? message;

  /// Optional label for a primary action button. Requires [onAction].
  final String? actionLabel;

  /// Optional callback for the primary action button. Requires [actionLabel].
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    assert(
      (actionLabel == null) == (onAction == null),
      'actionLabel and onAction must both be provided or both be null.',
    );

    return Semantics(
      container: true,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(GtSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: GtSpacing.md),
              Text(
                title,
                style: textTheme.titleSmall,
                textAlign: TextAlign.center,
              ),
              if (message != null) ...[
                const SizedBox(height: GtSpacing.xs),
                Text(
                  message!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: GtSpacing.lg),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
