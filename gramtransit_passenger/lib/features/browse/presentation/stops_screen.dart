import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_empty_state.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_error_view.dart';
import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/error/app_failure.dart';
import 'package:gramtransit_passenger/core/error/app_failure_message.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/browse/presentation/browse_display_format.dart';
import 'package:gramtransit_passenger/features/browse/presentation/widgets/browse_sample_data_notice.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// Screen listing all stops in the loaded timetable with search functionality.
class StopsScreen extends ConsumerStatefulWidget {
  const StopsScreen({super.key, this.onStopTap});

  /// Optional callback invoked when a stop row is tapped.
  /// Passes the canonical [StopId].
  final ValueChanged<StopId>? onStopTap;

  @override
  ConsumerState<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends ConsumerState<StopsScreen> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_query != _searchController.text) {
      setState(() {
        _query = _searchController.text;
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  static String _resolveErrorMessage(Object error, BuildContext context) {
    if (error is AppFailure) {
      return AppFailureMessage.of(error, context.l10n);
    }
    return context.l10n.homeTimetableLoadError;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final timetableAsync = ref.watch(timetableProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.stopsTitle)),
      body: SafeArea(
        child: timetableAsync.when(
          loading: () => const GtLoadingView(),
          error: (error, _) => GtErrorView(
            message: _resolveErrorMessage(error, context),
            onRetry: () => ref.refresh(timetableProvider),
          ),
          data: (timetable) {
            if (timetable.stops.isEmpty) {
              return GtEmptyState(
                icon: Icons.place_outlined,
                title: l10n.homeNoStopsAvailable,
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: GtSpacing.md),
              child: Column(
                children: [
                  const SizedBox(height: GtSpacing.sm),
                  if (timetable.info.isSampleData) ...[
                    const BrowseSampleDataNotice(compact: true),
                    const SizedBox(height: GtSpacing.sm),
                  ],
                  SearchBar(
                    controller: _searchController,
                    hintText: l10n.stopsSearchHint,
                    leading: const Icon(Icons.search_rounded),
                    trailing: _query.isNotEmpty
                        ? [
                            IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              tooltip: l10n.stopsClearSearch,
                              onPressed: () {
                                _searchController.clear();
                              },
                            ),
                          ]
                        : null,
                  ),
                  const SizedBox(height: GtSpacing.sm),
                  Expanded(child: _buildStopsList(context)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStopsList(BuildContext context) {
    final l10n = context.l10n;
    final searchAsync = ref.watch(
      stopSearchProvider(StopSearchQuery(query: _query)),
    );

    return searchAsync.when(
      loading: () => const GtLoadingView(),
      error: (error, _) => GtErrorView(
        message: _resolveErrorMessage(error, context),
        onRetry: () => ref.refresh(timetableProvider),
      ),
      data: (stops) {
        if (stops.isEmpty) {
          return GtEmptyState(
            icon: Icons.search_off_rounded,
            title: l10n.stopsNoStopsFound,
          );
        }

        return ListView.separated(
          itemCount: stops.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final stop = stops[index];
            return _buildStopRow(context, stop);
          },
        );
      },
    );
  }

  Widget _buildStopRow(BuildContext context, TransitStop stop) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final stopName = resolveLocalizedText(stop.name, context);

    return Semantics(
      button: true,
      label: stopName,
      child: InkWell(
        onTap: () => widget.onStopTap?.call(stop.id),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: GtSpacing.sm,
              vertical: GtSpacing.md,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: GtSpacing.md),
                Expanded(
                  child: Text(
                    stopName,
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
