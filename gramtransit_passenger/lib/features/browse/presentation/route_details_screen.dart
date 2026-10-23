import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/error/app_failure_message.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/browse/application/browse_providers.dart';
import 'package:gramtransit_passenger/features/browse/presentation/browse_display_format.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_sample_data_notice.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_scheduled_times_note.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/route_catalog.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// Full-screen Route Details screen displaying route identity, route variants,
/// ordered stop sequences, and scheduled trips per variant.
///
/// Pure presentation component representing the future `/routes/:routeId` path.
/// Does not perform URL parsing or internal router navigation.
class RouteDetailsScreen extends ConsumerWidget {
  const RouteDetailsScreen({
    super.key,
    required this.routeId,
    this.onBack,
    this.onTripTap,
  });

  /// Canonical identifier of the route to display.
  final RouteId routeId;

  /// Optional callback invoked when navigating back from not-found state.
  final VoidCallback? onBack;

  /// Optional callback invoked when a scheduled trip row is tapped.
  final ValueChanged<TripId>? onTripTap;

  static String _resolveErrorMessage(Object error, BuildContext context) {
    if (error is AppFailure) {
      return AppFailureMessage.of(error, context.l10n);
    }
    return context.l10n.homeTimetableLoadError;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final routeDetailsAsync = ref.watch(routeDetailsProvider(routeId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.routeDetailsTitle)),
      body: SafeArea(
        child: routeDetailsAsync.when(
          loading: () => const GtLoadingView(),
          error: (error, _) => GtErrorView(
            message: _resolveErrorMessage(error, context),
            onRetry: () => ref.refresh(timetableProvider),
          ),
          data: (details) {
            if (details == null) {
              return GtEmptyState(
                icon: Icons.alt_route_rounded,
                title: l10n.routeNotFoundTitle,
                message: l10n.routeNotFoundMessage,
                actionLabel: onBack != null ? l10n.routeNotFoundAction : null,
                onAction: onBack != null ? () => onBack!.call() : null,
              );
            }

            final timetableAsync = ref.watch(timetableProvider);
            final timetable = timetableAsync.asData?.value;
            final isSampleData = timetable?.info.isSampleData ?? false;
            final stops = timetable?.stops ?? const <TransitStop>[];
            final stopMap = {for (final s in stops) s.id: s};

            return SingleChildScrollView(
              padding: const EdgeInsets.all(GtSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildRouteHeader(context, details.route),
                  const SizedBox(height: GtSpacing.md),
                  if (isSampleData) ...[
                    const BrowseSampleDataNotice(),
                    const SizedBox(height: GtSpacing.md),
                  ],
                  if (details.variants.isEmpty)
                    _buildZeroVariantsView(context)
                  else ...[
                    for (var i = 0; i < details.variants.length; i++) ...[
                      if (i > 0) const SizedBox(height: GtSpacing.lg),
                      _buildVariantSection(
                        context,
                        variant: details.variants[i],
                        index: i,
                        stopMap: stopMap,
                      ),
                    ],
                    const SizedBox(height: GtSpacing.lg),
                    const BrowseScheduledTimesNote(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRouteHeader(BuildContext context, TransitRoute route) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final shortName = resolveLocalizedText(route.shortName, context);
    final longName = resolveLocalizedText(route.longName, context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(GtSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: GtSpacing.md,
                vertical: GtSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                shortName,
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: GtSpacing.md),
            Expanded(
              child: Text(
                longName,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZeroVariantsView(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(GtSpacing.lg),
        child: Row(
          children: [
            Icon(
              Icons.info_outline_rounded,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: GtSpacing.md),
            Expanded(
              child: Text(
                l10n.routeNoScheduledTrips,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariantSection(
    BuildContext context, {
    required RouteVariant variant,
    required int index,
    required Map<StopId, TransitStop> stopMap,
  }) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final originStop = stopMap[variant.firstStopId];
    final destStop = stopMap[variant.lastStopId];
    final originName = originStop != null
        ? resolveLocalizedText(originStop.name, context)
        : variant.firstStopId.value;
    final destName = destStop != null
        ? resolveLocalizedText(destStop.name, context)
        : variant.lastStopId.value;

    final variantTitle = l10n.routeVariantTitle(
      index + 1,
      originName,
      destName,
    );

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(GtSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              variantTitle,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: GtSpacing.md),
            Text(
              l10n.routeStopsHeading,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: GtSpacing.sm),
            _buildStopSequence(
              context,
              stopIds: variant.stopIds,
              stopMap: stopMap,
            ),
            const SizedBox(height: GtSpacing.md),
            Text(
              l10n.routeScheduledTripsHeading,
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: GtSpacing.sm),
            _buildScheduledTripsList(context, trips: variant.trips),
          ],
        ),
      ),
    );
  }

  Widget _buildStopSequence(
    BuildContext context, {
    required List<StopId> stopIds,
    required Map<StopId, TransitStop> stopMap,
  }) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        for (var i = 0; i < stopIds.length; i++) ...[
          () {
            final stopId = stopIds[i];
            final stop = stopMap[stopId];
            final stopName = stop != null
                ? resolveLocalizedText(stop.name, context)
                : stopId.value;
            final isFirst = i == 0;
            final isLast = i == stopIds.length - 1;

            return Semantics(
              label: l10n.routeStopSequenceItemSemantics(
                i + 1,
                stopIds.length,
                stopName,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFirst || isLast
                            ? colorScheme.primary
                            : colorScheme.surfaceContainerHighest,
                        border: Border.all(
                          color: isFirst || isLast
                              ? colorScheme.primary
                              : colorScheme.outlineVariant,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isFirst || isLast
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: GtSpacing.sm),
                    Expanded(
                      child: Text(
                        stopName,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: isFirst || isLast
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }(),
        ],
      ],
    );
  }

  Widget _buildScheduledTripsList(
    BuildContext context, {
    required List<ScheduledTrip> trips,
  }) {
    return Column(
      children: [
        for (var i = 0; i < trips.length; i++) ...[
          if (i > 0) const SizedBox(height: GtSpacing.xs),
          _buildTripRow(context, trip: trips[i]),
        ],
      ],
    );
  }

  Widget _buildTripRow(BuildContext context, {required ScheduledTrip trip}) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final firstDeparture = trip.stopTimes.first.departureTime;
    final lastArrival = trip.stopTimes.last.arrivalTime;

    final formattedDep = formatServiceTime(context, firstDeparture);
    final formattedArr = formatServiceTime(context, lastArrival);

    final depTimeStr = formattedDep.isNextDay
        ? '${formattedDep.clockTime} ${l10n.tripDetailsNextDaySemantics}'
        : formattedDep.clockTime;
    final arrTimeStr = formattedArr.isNextDay
        ? '${formattedArr.clockTime} ${l10n.tripDetailsNextDaySemantics}'
        : formattedArr.clockTime;

    final depSemanticLabel = l10n.routeDepartureEndpointSemantics(depTimeStr);
    final arrSemanticLabel = l10n.routeArrivalEndpointSemantics(arrTimeStr);

    final runningDays = formatServiceDays(context, trip.serviceDays);

    return Card(
      margin: EdgeInsets.zero,
      color: colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTripTap != null ? () => onTripTap!(trip.id) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GtSpacing.md,
              vertical: GtSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _buildEndpointTime(
                            context,
                            formattedTime: formattedDep,
                            semanticLabel: depSemanticLabel,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: GtSpacing.xs,
                            ),
                            child: ExcludeSemantics(
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          _buildEndpointTime(
                            context,
                            formattedTime: formattedArr,
                            semanticLabel: arrSemanticLabel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        runningDays,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTripTap != null)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndpointTime(
    BuildContext context, {
    required FormattedEndpointTime formattedTime,
    required String semanticLabel,
  }) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              formattedTime.clockTime,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (formattedTime.isNextDay) ...[
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
