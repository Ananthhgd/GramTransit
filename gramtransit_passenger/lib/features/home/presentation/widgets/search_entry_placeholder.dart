import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_radius.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Non-functional visual placeholder for the future search experience.
///
/// Intentionally does NOT respond to taps, navigate, or open the keyboard.
/// Presents itself to assistive technology as informational content only —
/// not as an actionable button — via an outer [Semantics] node with
/// [Semantics.readOnly] and an inner [ExcludeSemantics].
class SearchEntryPlaceholder extends StatelessWidget {
  const SearchEntryPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: l10n.homeSearchComingSoon,
      readOnly: true,
      child: ExcludeSemantics(
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: GtRadius.pillRadius,
          ),
          padding: const EdgeInsets.symmetric(horizontal: GtSpacing.lg),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: GtSpacing.sm),
              Expanded(
                child: Text(
                  l10n.homeSearchPlaceholder,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
