import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/journey_search/presentation/widgets/scheduled_journey_card.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/scheduled_journey.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// Presentation section displaying direct scheduled journeys or guidance/empty/loading/error states.
class JourneyResultsSection extends ConsumerWidget {
  const JourneyResultsSection({
    super.key,
    required this.boardingStopId,
    required this.alightingStopId,
    this.onJourneySelected,
  });

  final StopId? boardingStopId;
  final StopId? alightingStopId;
  final ValueChanged<ScheduledJourney>? onJourneySelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final fromId = boardingStopId;
    final toId = alightingStopId;

    // Guidance / idle state when either stop is unselected or identical
    if (fromId == null || toId == null || fromId == toId) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(GtSpacing.xl),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.route_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: GtSpacing.md),
                Text(
                  l10n.journeySearchChooseStopsPrompt,
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

    final query = JourneyQuery(boardingStopId: fromId, alightingStopId: toId);

    final upcomingAsync = ref.watch(upcomingJourneysProvider(query));

    return upcomingAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: GtSpacing.xl),
        child: GtLoadingView(),
      ),
      error: (error, _) => GtErrorView(
        message: l10n.errorUnexpected,
        onRetry: () => ref.invalidate(upcomingJourneysProvider(query)),
      ),
      data: (upcoming) {
        if (upcoming.current.isNotEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final journey in upcoming.current)
                Padding(
                  padding: const EdgeInsets.only(bottom: GtSpacing.sm),
                  child: ScheduledJourneyCard(
                    journey: journey,
                    showDate: false,
                    onTap: onJourneySelected != null
                        ? () => onJourneySelected!(journey)
                        : null,
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
                          l10n.journeySearchNoMoreJourneysToday,
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
                l10n.journeySearchNextScheduledJourneys,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: GtSpacing.sm),
              for (final journey in upcoming.nextLater)
                Padding(
                  padding: const EdgeInsets.only(bottom: GtSpacing.sm),
                  child: ScheduledJourneyCard(
                    journey: journey,
                    showDate: true,
                    onTap: onJourneySelected != null
                        ? () => onJourneySelected!(journey)
                        : null,
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
                    l10n.journeySearchNoDirectJourneysTitle,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: GtSpacing.xs),
                  Text(
                    l10n.journeySearchNoDirectJourneysMessage,
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
