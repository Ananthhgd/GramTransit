import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_display_format.dart';
import 'package:gramtransit_passenger/features/transit/domain/trip_occurrence.dart';

/// Dedicated presentation widget for an upcoming scheduled trip departure.
///
/// Strictly non-interactive in P5. Does not include navigation affordances,
/// tap handlers, or live status indicators.
class UpcomingTripCard extends StatelessWidget {
  const UpcomingTripCard({
    super.key,
    required this.occurrence,
    this.showDate = false,
  });

  /// The scheduled trip occurrence to display.
  final TripOccurrence occurrence;

  /// Whether to display a localized date alongside the scheduled clock time.
  /// Typically true for [UpcomingTrips.nextLater] departures on later dates.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    final departureText = showDate
        ? formatNextLaterDeparture(context, occurrence.scheduledDeparture)
        : formatScheduledTime(context, occurrence.scheduledDeparture);

    final destinationText = l10n.homeTripDestination(
      resolveLocalizedText(occurrence.destinationName, context),
    );

    final routeText = l10n.homeTripRoute(
      resolveLocalizedText(occurrence.routeShortName, context),
      resolveLocalizedText(occurrence.routeLongName, context),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GtSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              departureText,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GtSpacing.xs),
            Text(destinationText, style: textTheme.bodyLarge),
            const SizedBox(height: GtSpacing.xs),
            Text(
              routeText,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
