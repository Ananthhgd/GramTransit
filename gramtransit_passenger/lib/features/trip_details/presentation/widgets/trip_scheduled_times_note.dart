import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Persistent schedule disclosure note explaining that stop times are scheduled.
class TripScheduledTimesNote extends StatelessWidget {
  const TripScheduledTimesNote({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      context.l10n.tripDetailsScheduledTimesNote,
      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}
