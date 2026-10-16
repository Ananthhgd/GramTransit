import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:gramtransit_passenger/app/router/app_routes.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/error/app_failure_message.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_display_format.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/home_stop_selector.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/sample_data_notice.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/scheduled_times_note.dart';
import 'package:gramtransit_passenger/features/home/presentation/widgets/upcoming_trip_card.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// The Home upcoming departures section backed by domain timetable and trips providers.
///
/// Controlled by parent for [selectedStopId] and [onStopSelected] (Model H-A).
class UpcomingDeparturesSection extends ConsumerWidget {
  const UpcomingDeparturesSection({
    super.key,
    required this.selectedStopId,
    required this.onStopSelected,
  });

  final StopId? selectedStopId;
  final ValueChanged<StopId?> onStopSelected;

  static String _resolveErrorMessage(Object error, BuildContext context) {
    if (error is AppFailure) {
      return AppFailureMessage.of(error, context.l10n);
    }
    return context.l10n.homeTimetableLoadError;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final timetableAsync = ref.watch(timetableProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.homeUpcomingDeparturesTitle,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GtSpacing.sm),
        timetableAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: GtSpacing.xl),
            child: GtLoadingView(),
          ),
          error: (error, _) => GtErrorView(
            message: _resolveErrorMessage(error, context),
            onRetry: () => ref.refresh(timetableProvider),
          ),
          data: (timetable) {
            if (timetable.stops.isEmpty) {
              return GtEmptyState(
                icon: Icons.directions_bus_rounded,
                title: l10n.homeNoStopsAvailable,
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScheduledTimesNote(),
                if (timetable.info.isSampleData) ...[
                  const SizedBox(height: GtSpacing.sm),
                  const SampleDataNotice(),
                ],
                const SizedBox(height: GtSpacing.md),
                HomeStopSelector(
                  stops: timetable.stops,
                  selectedStopId: selectedStopId,
                  onStopSelected: onStopSelected,
                ),
                const SizedBox(height: GtSpacing.lg),
                _buildResultsArea(context, ref, timetable),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildResultsArea(
    BuildContext context,
    WidgetRef ref,
    Timetable timetable,
  ) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (selectedStopId == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(GtSpacing.xl),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.touch_app_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: GtSpacing.md),
                Text(
                  l10n.homeChooseStopPrompt,
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
    }

    final upcomingAsync = ref.watch(upcomingTripsProvider(selectedStopId!));

    return upcomingAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: GtSpacing.xl),
        child: GtLoadingView(),
      ),
      error: (error, _) => GtErrorView(
        message: l10n.errorUnexpected,
        onRetry: () => ref.invalidate(upcomingTripsProvider(selectedStopId!)),
      ),
      data: (upcoming) {
        final selectedStop = timetable.stops.cast<TransitStop?>().firstWhere(
          (s) => s?.id == selectedStopId,
          orElse: () => null,
        );
        final stopName = selectedStop != null
            ? resolveLocalizedText(selectedStop.name, context)
            : '';

        if (upcoming.current.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final occurrence in upcoming.current)
                Padding(
                  padding: const EdgeInsets.only(bottom: GtSpacing.sm),
                  child: UpcomingTripCard(
                    occurrence: occurrence,
                    showDate: false,
                    onTap: () {
                      context.pushNamed(
                        AppRoutes.tripDetails,
                        pathParameters: {'tripId': occurrence.tripId.value},
                      );
                    },
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
                  child: UpcomingTripCard(
                    occurrence: occurrence,
                    showDate: true,
                    onTap: () {
                      context.pushNamed(
                        AppRoutes.tripDetails,
                        pathParameters: {'tripId': occurrence.tripId.value},
                      );
                    },
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
    );
  }
}
