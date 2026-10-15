import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_display_format.dart';
import 'package:gramtransit_passenger/features/transit/domain/trip_occurrence.dart';

/// Dedicated presentation widget for an upcoming scheduled trip departure.
///
/// In P6, the whole card is an interactive Material tap surface that triggers
/// [onTap] to navigate to trip details, featuring a decorative trailing chevron
/// and accessible button semantics.
class UpcomingTripCard extends StatelessWidget {
  const UpcomingTripCard({
    super.key,
    required this.occurrence,
    required this.onTap,
    this.showDate = false,
  });

  /// The scheduled trip occurrence to display.
  final TripOccurrence occurrence;

  /// Callback invoked when this card is tapped.
  final VoidCallback onTap;

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
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: true,
        hint: l10n.homeTripCardOpenHint,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(GtSpacing.lg),
            child: Row(
              children: [
                Expanded(
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
                const SizedBox(width: GtSpacing.sm),
                ExcludeSemantics(
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurfaceVariant,
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
