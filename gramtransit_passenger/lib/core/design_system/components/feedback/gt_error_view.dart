import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Generic localized error presentation.
///
/// Callers are responsible for providing a ready-made localized [message] —
/// typically obtained from [AppFailureMessage.of] — so this widget remains
/// decoupled from the failure model.
///
/// If [onRetry] is provided, a "Try again" button is shown with a minimum
/// touch target of 48 × 48 dp (Material accessibility guidance).
class GtErrorView extends StatelessWidget {
  const GtErrorView({super.key, required this.message, this.onRetry});

  /// A ready-made localized error message.
  final String message;

  /// Optional callback for a retry action. If null, no retry button is shown.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(GtSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: GtSpacing.md),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: GtSpacing.lg),
              // Minimum 48 × 48 dp touch target per Material accessibility guidance.
              SizedBox(
                height: 48,
                child: TextButton(
                  onPressed: onRetry,
                  child: Text(context.l10n.actionTryAgain),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
