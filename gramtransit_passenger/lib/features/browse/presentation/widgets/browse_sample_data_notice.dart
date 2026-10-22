import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Notice displayed only when the loaded timetable contains sample testing data.
///
/// Supports standard form (e.g. for detail screens) and compact form (e.g. for list screens).
class BrowseSampleDataNotice extends StatelessWidget {
  const BrowseSampleDataNotice({super.key, this.compact = false});

  /// Whether to use compact padding for denser list screen layouts.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: GtSpacing.md,
        vertical: compact ? GtSpacing.xs : GtSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: GtSpacing.sm),
          Expanded(
            child: Text(
              context.l10n.homeSampleDataNotice,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
