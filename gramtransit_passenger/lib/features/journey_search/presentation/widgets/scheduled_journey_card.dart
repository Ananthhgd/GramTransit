import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/journey_display_format.dart';
import 'package:gramtransit_passenger/features/transit/domain/scheduled_journey.dart';

/// Presentation card displaying a single scheduled direct journey.
class ScheduledJourneyCard extends StatelessWidget {
  const ScheduledJourneyCard({
    super.key,
    required this.journey,
    this.onTap,
    this.showDate = false,
  });

  /// The scheduled journey to display.
  final ScheduledJourney journey;

  /// Optional callback invoked when this card is tapped.
  final VoidCallback? onTap;

  /// Whether to display a localized date alongside departure time.
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    final departureText = showDate
        ? formatNextLaterDeparture(context, journey.scheduledDeparture)
        : formatScheduledTime(context, journey.scheduledDeparture);

    final arrivalText = formatScheduledTime(context, journey.scheduledArrival);
    final durationText = formatJourneyDuration(
      context,
      journey.scheduledDuration,
    );

    final routeContext = journey.tripHeadsign.english.isNotEmpty
        ? l10n.journeyTripRoute(
            journey.routeShortName.english,
            journey.tripHeadsign.english,
          )
        : l10n.journeyTripRouteFallback(
            journey.routeShortName.english,
            journey.routeLongName.english,
          );

    final stopsContext =
        '${journey.boardingStopName.english} → ${journey.alightingStopName.english}';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Semantics(
        button: onTap != null,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(GtSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      departureText,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      ' → ',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      arrivalText,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (journey.arrivesOnLaterCalendarDay) ...[
                      const SizedBox(width: GtSpacing.xs),
                      Semantics(
                        label: l10n.tripDetailsNextDaySemantics,
                        child: Text(
                          l10n.tripDetailsNextDayMarker,
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GtSpacing.sm,
                        vertical: GtSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        durationText,
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: GtSpacing.sm),
                Text(
                  stopsContext,
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: GtSpacing.xs),
                Text(
                  routeContext,
                  style: textTheme.bodySmall?.copyWith(
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
