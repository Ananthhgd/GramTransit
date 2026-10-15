import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/trip_details/application/trip_details_provider.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/trip_display_format.dart';

/// Presentation header for the Trip Details screen.
///
/// Displays route short and long names, origin to destination endpoints,
/// and formatted running/service days.
class TripHeader extends StatelessWidget {
  const TripHeader({super.key, required this.details});

  final TripDetails details;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    final shortName = resolveLocalizedText(details.routeShortName, context);
    final longName = resolveLocalizedText(details.routeLongName, context);
    final firstStopName = resolveLocalizedText(
      details.stops.first.stopName,
      context,
    );
    final lastStopName = resolveLocalizedText(
      details.stops.last.stopName,
      context,
    );
    final serviceDaysText = formatServiceDays(context, details.serviceDays);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GtSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.tripDetailsRouteLabel(shortName),
              style: textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: GtSpacing.xs),
            Text(
              longName,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: GtSpacing.xs),
            Text(
              l10n.tripDetailsOriginToDestination(firstStopName, lastStopName),
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: GtSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: GtSpacing.xs),
                Expanded(
                  child: Text(
                    serviceDaysText,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
