import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/generated/app_localizations.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/trip_details/application/trip_details_provider.dart';
import 'package:gramtransit_passenger/features/trip_details/presentation/trip_display_format.dart';

/// Ordered list of stops and scheduled times for a trip.
class TripStopList extends StatelessWidget {
  const TripStopList({super.key, required this.stops});

  final List<TripStopRow> stops;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: GtSpacing.md,
          vertical: GtSpacing.lg,
        ),
        child: Column(
          children: [
            for (var i = 0; i < stops.length; i++)
              _TripStopRowWidget(
                row: stops[i],
                isFirst: i == 0,
                isLast: i == stops.length - 1,
              ),
          ],
        ),
      ),
    );
  }
}

class _TripStopRowWidget extends StatelessWidget {
  const _TripStopRowWidget({
    required this.row,
    required this.isFirst,
    required this.isLast,
  });

  final TripStopRow row;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    final stopName = resolveLocalizedText(row.stopName, context);
    final formattedArr = formatServiceTime(context, row.arrival);
    final formattedDep = formatServiceTime(context, row.departure);

    final arrSemantic = l10n.tripDetailsScheduledArrivalSemantics(
      formattedArr.isNextDay
          ? '${formattedArr.clockTime} ${l10n.tripDetailsNextDaySemantics}'
          : formattedArr.clockTime,
    );
    final depSemantic = l10n.tripDetailsScheduledDepartureSemantics(
      formattedDep.isNextDay
          ? '${formattedDep.clockTime} ${l10n.tripDetailsNextDaySemantics}'
          : formattedDep.clockTime,
    );

    return Semantics(
      container: true,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Decorative timeline indicator excluded from screen readers
            ExcludeSemantics(
              child: SizedBox(
                width: 24,
                child: Column(
                  children: [
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isFirst
                            ? Colors.transparent
                            : colorScheme.outlineVariant,
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (isFirst || isLast)
                            ? colorScheme.primary
                            : colorScheme.outline,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        color: isLast
                            ? Colors.transparent
                            : colorScheme.outlineVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: GtSpacing.sm),
            // Stop details and scheduled times
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: GtSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            stopName,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (row.position == TripStopPosition.first) ...[
                          const SizedBox(width: GtSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GtSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.tripDetailsFirstStop,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ] else if (row.position == TripStopPosition.last) ...[
                          const SizedBox(width: GtSpacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GtSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              l10n.tripDetailsLastStop,
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: GtSpacing.xs),
                    _buildTimeDisplay(
                      context: context,
                      formattedArr: formattedArr,
                      formattedDep: formattedDep,
                      arrSemantic: arrSemantic,
                      depSemantic: depSemantic,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDisplay({
    required BuildContext context,
    required FormattedServiceTime formattedArr,
    required FormattedServiceTime formattedDep,
    required String arrSemantic,
    required String depSemantic,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    if (row.position == TripStopPosition.first) {
      // First stop: departure only
      return _buildTimeRow(
        text: l10n.tripDetailsDeparts(formattedDep.clockTime),
        semanticLabel: depSemantic,
        isNextDay: formattedDep.isNextDay,
        colorScheme: colorScheme,
        textTheme: textTheme,
        l10n: l10n,
      );
    } else if (row.position == TripStopPosition.last) {
      // Last stop: arrival only
      return _buildTimeRow(
        text: l10n.tripDetailsArrives(formattedArr.clockTime),
        semanticLabel: arrSemantic,
        isNextDay: formattedArr.isNextDay,
        colorScheme: colorScheme,
        textTheme: textTheme,
        l10n: l10n,
      );
    } else if (row.arrival == row.departure) {
      // Intermediate equal arrival and departure: single clock time
      return _buildTimeRow(
        text: formattedDep.clockTime,
        semanticLabel: depSemantic,
        isNextDay: formattedDep.isNextDay,
        colorScheme: colorScheme,
        textTheme: textTheme,
        l10n: l10n,
      );
    } else {
      // Intermediate differing arrival and departure: both
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeRow(
            text: l10n.tripDetailsArrives(formattedArr.clockTime),
            semanticLabel: arrSemantic,
            isNextDay: formattedArr.isNextDay,
            colorScheme: colorScheme,
            textTheme: textTheme,
            l10n: l10n,
          ),
          const SizedBox(height: 2),
          _buildTimeRow(
            text: l10n.tripDetailsDeparts(formattedDep.clockTime),
            semanticLabel: depSemantic,
            isNextDay: formattedDep.isNextDay,
            colorScheme: colorScheme,
            textTheme: textTheme,
            l10n: l10n,
          ),
        ],
      );
    }
  }

  Widget _buildTimeRow({
    required String text,
    required String semanticLabel,
    required bool isNextDay,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required AppLocalizations l10n,
  }) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Flexible(
            child: Text(
              text,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (isNextDay) ...[
            const SizedBox(width: GtSpacing.xs),
            Text(
              l10n.tripDetailsNextDayMarker,
              style: textTheme.labelSmall?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
