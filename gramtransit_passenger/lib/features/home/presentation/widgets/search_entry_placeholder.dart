import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_radius.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Interactive search entry pill on the Home screen that launches Journey Search.
///
/// Presents itself to assistive technology as an actionable button with the
/// search prompt label.
class SearchEntryPlaceholder extends StatelessWidget {
  const SearchEntryPlaceholder({super.key, this.onTap});

  /// Optional callback invoked when the search entry pill is tapped.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: l10n.homeSearchPlaceholder,
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: GtRadius.pillRadius,
        child: InkWell(
          borderRadius: GtRadius.pillRadius,
          onTap: onTap,
          child: Container(
            height: 56,
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
      ),
    );
  }
}
