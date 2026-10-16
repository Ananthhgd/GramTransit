import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';

/// Persistent schedule disclosure explaining that departures and arrivals are scheduled times.
class JourneyScheduledTimesNote extends StatelessWidget {
  const JourneyScheduledTimesNote({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Text(
      context.l10n.homeScheduledDisclosure,
      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
    );
  }
}
