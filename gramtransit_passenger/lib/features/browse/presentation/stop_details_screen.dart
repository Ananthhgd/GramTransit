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
import 'package:gramtransit_passenger/features/browse/presentation/widgets/stop_upcoming_trip_card.dart';
import 'package:gramtransit_passenger/features/saved/application/saved_transit_controller.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// Full-screen Stop Details screen displaying stop identity, serving routes,
/// and upcoming scheduled departures.
class StopDetailsScreen extends ConsumerWidget {
  const StopDetailsScreen({
    super.key,
    required this.stopId,
    this.onPlanJourney,
    this.onBack,
    this.onTripTap,
  });

  /// Canonical identifier of the stop to display.
  final StopId stopId;

  /// Optional callback invoked when "Plan journey from here" is tapped.
  /// Passes the canonical [StopId].
  final ValueChanged<StopId>? onPlanJourney;

  /// Optional callback invoked when navigating back from not-found state.
  final VoidCallback? onBack;

  /// Optional callback invoked when an upcoming departure card is tapped.
  final ValueChanged<TripId>? onTripTap;

  static String _resolveErrorMessage(Object error, BuildContext context) {
    if (error is AppFailure) {
      return AppFailureMessage.of(error, context.l10n);
    }
    return context.l10n.homeTimetableLoadError;
  }

  Future<void> _toggleSaveStop(BuildContext context, WidgetRef ref) async {
    final isSaved = ref
        .read(savedTransitControllerProvider)
        .containsStop(stopId);
    try {
      if (isSaved) {
        await ref
            .read(savedTransitControllerProvider.notifier)
            .unsaveStop(stopId);
      } else {
        await ref
            .read(savedTransitControllerProvider.notifier)
            .saveStop(stopId);
      }
    } on StorageFailure {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.errorStorage)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final stopDetailsAsync = ref.watch(stopDetailsProvider(stopId));
    final isSaved = ref
        .watch(savedTransitControllerProvider)
        .containsStop(stopId);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.stopDetailsTitle),
        actions: [
          IconButton(
            constraints: const BoxConstraints(minWidth: 48.0, minHeight: 48.0),
            icon: Icon(
              isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            ),
            tooltip: isSaved ? 'Remove saved stop' : 'Save stop',
            onPressed: () => _toggleSaveStop(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: stopDetailsAsync.when(
          loading: () => const GtLoadingView(),
          error: (error, _) => GtErrorView(
            message: _resolveErrorMessage(error, context),
            onRetry: () => ref.refresh(timetableProvider),
          ),
          data: (details) {
            if (details == null) {
              return GtEmptyState(
                icon: Icons.place_outlined,
                title: l10n.stopNotFoundTitle,
                message: l10n.stopNotFoundMessage,
                actionLabel: l10n.stopNotFoundAction,
                onAction: () => onBack?.call(),
              );
            }

            final timetableAsync = ref.watch(timetableProvider);
            final isSampleData =
                timetableAsync.asData?.value.info.isSampleData ?? false;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(GtSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStopHeader(context, details),
                  const SizedBox(height: GtSpacing.md),
                  if (isSampleData) ...[
                    const BrowseSampleDataNotice(),
                    const SizedBox(height: GtSpacing.md),
                  ],
                  _buildPlanJourneyButton(context),
                  const SizedBox(height: GtSpacing.lg),
                  _buildRoutesServingSection(context, details),
                  const SizedBox(height: GtSpacing.lg),
                  _buildUpcomingDeparturesSection(context, ref, details),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStopHeader(BuildContext context, StopDetails details) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final stopName = resolveLocalizedText(details.stop.name, context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GtSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.place_rounded, size: 32, color: colorScheme.primary),
            const SizedBox(width: GtSpacing.md),
            Expanded(
              child: Text(
                stopName,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanJourneyButton(BuildContext context) {
    final l10n = context.l10n;

    return SizedBox(
      height: 48,
      child: FilledButton.icon(
        onPressed: () => onPlanJourney?.call(stopId),
        icon: const Icon(Icons.alt_route_rounded),
        label: Text(l10n.stopPlanJourneyFromHere),
      ),
    );
  }

  Widget _buildRoutesServingSection(BuildContext context, StopDetails details) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.stopRoutesServingTitle,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GtSpacing.sm),
        if (details.routes.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(GtSpacing.md),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: GtSpacing.sm),
                  Expanded(
                    child: Text(
                      l10n.stopNoRoutesServing,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          for (final route in details.routes) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(GtSpacing.md),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GtSpacing.sm,
                        vertical: GtSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        resolveLocalizedText(route.shortName, context),
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: GtSpacing.md),
                    Expanded(
                      child: Text(
                        resolveLocalizedText(route.longName, context),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GtSpacing.xs),
          ],
      ],
    );
  }

  Widget _buildUpcomingDeparturesSection(
    BuildContext context,
    WidgetRef ref,
    StopDetails details,
  ) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final stopName = resolveLocalizedText(details.stop.name, context);

    final upcomingAsync = ref.watch(upcomingTripsProvider(stopId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.stopUpcomingDeparturesTitle,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GtSpacing.xs),
        const BrowseScheduledTimesNote(),
        const SizedBox(height: GtSpacing.sm),
        upcomingAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: GtSpacing.xl),
            child: GtLoadingView(),
          ),
          error: (error, _) => GtErrorView(
            message: l10n.errorUnexpected,
            onRetry: () => ref.invalidate(upcomingTripsProvider(stopId)),
          ),
          data: (upcoming) {
            if (upcoming.current.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final occurrence in upcoming.current)
                    Padding(
                      padding: const EdgeInsets.only(bottom: GtSpacing.sm),
                      child: StopUpcomingTripCard(
                        occurrence: occurrence,
                        showDate: false,
                        onTap: () => onTripTap?.call(occurrence.tripId),
                      ),
                    ),
                ],
              );
            }

            if (upcoming.nextLater.isNotEmpty) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(GtSpacing.md),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 20,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: GtSpacing.sm),
                          Expanded(
                            child: Text(
                              l10n.homeNoMoreDeparturesForNow(stopName),
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: GtSpacing.md),
                  Text(
                    l10n.homeNextScheduledBus,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: GtSpacing.sm),
                  for (final occurrence in upcoming.nextLater)
                    Padding(
                      padding: const EdgeInsets.only(bottom: GtSpacing.sm),
                      child: StopUpcomingTripCard(
                        occurrence: occurrence,
                        showDate: true,
                        onTap: () => onTripTap?.call(occurrence.tripId),
                      ),
                    ),
                ],
              );
            }

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(GtSpacing.xl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 48,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: GtSpacing.md),
                      Text(
                        l10n.homeNoUpcomingDepartures(stopName),
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
