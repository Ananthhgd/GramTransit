import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Displays the upcoming departures section heading and an empty-state card.
/// No fake bus data — timetables will replace this placeholder in a later phase.
class UpcomingDeparturesPlaceholder extends StatelessWidget {
  const UpcomingDeparturesPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeUpcomingDeparturesTitle,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GtSpacing.sm),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(GtSpacing.xl),
            child: Column(
              children: [
                Icon(
                  Icons.schedule_rounded,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: GtSpacing.md),
                Text(
                  l10n.homeUpcomingDeparturesEmptyTitle,
                  style: textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: GtSpacing.xs),
                Text(
                  l10n.homeUpcomingDeparturesEmptyMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
