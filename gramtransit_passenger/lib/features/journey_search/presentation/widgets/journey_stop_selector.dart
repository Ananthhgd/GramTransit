import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gramtransit_passenger/core/design_system/components/feedback/gt_loading_view.dart';
import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';
import 'package:gramtransit_passenger/features/transit/providers/transit_providers.dart';

/// Accessible Material 3 stop search selector backed by [SearchAnchor]
/// and [stopSearchProvider].
class JourneyStopSelector extends ConsumerStatefulWidget {
  const JourneyStopSelector({
    super.key,
    required this.label,
    required this.hintText,
    required this.selectedStopId,
    required this.onStopSelected,
    this.excludedStopId,
  });

  /// Visible and accessible label for this selector (e.g. "From" or "To").
  final String label;

  /// Placeholder text when no stop is selected.
  final String hintText;

  /// Currently selected [StopId], if any.
  final StopId? selectedStopId;

  /// Callback when a stop is selected or cleared.
  final ValueChanged<StopId?> onStopSelected;

  /// Optional stop to exclude from suggestions (e.g. exclude From in To selector).
  final StopId? excludedStopId;

  @override
  ConsumerState<JourneyStopSelector> createState() =>
      _JourneyStopSelectorState();
}

class _JourneyStopSelectorState extends ConsumerState<JourneyStopSelector> {
  late final SearchController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SearchController();
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final name = _resolveSelectedStopName();
        if (name != null) {
          _controller.text = name;
        }
      }
    });
  }

  @override
  void didUpdateWidget(JourneyStopSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedStopId != oldWidget.selectedStopId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.isAttached && !_controller.isOpen) {
          final name = _resolveSelectedStopName();
          _controller.text = name ?? '';
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    // When the search view closes without a selection, restore the selected stop's name.
    if (_controller.isAttached && !_controller.isOpen) {
      final currentName = _resolveSelectedStopName() ?? '';
      if (_controller.text != currentName) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _controller.isAttached && !_controller.isOpen) {
            _controller.text = currentName;
          }
        });
      }
    }
  }

  String? _resolveSelectedStopName() {
    if (widget.selectedStopId == null) return null;
    final timetableAsync = ref.read(timetableProvider);
    final timetable = timetableAsync.asData?.value;
    if (timetable == null) return null;
    final stop = timetable.stops.cast<TransitStop?>().firstWhere(
      (s) => s?.id == widget.selectedStopId,
      orElse: () => null,
    );
    return stop?.name.english;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Reactively update controller text when timetable loads for the first time
    ref.listen<AsyncValue<Timetable>>(timetableProvider, (_, next) {
      if (next.hasValue && widget.selectedStopId != null) {
        final stop = next.requireValue.stops.cast<TransitStop?>().firstWhere(
          (s) => s?.id == widget.selectedStopId,
          orElse: () => null,
        );
        if (stop != null && _controller.isAttached && !_controller.isOpen) {
          _controller.text = stop.name.english;
        }
      }
    });

    final isSelected = widget.selectedStopId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: GtSpacing.xs),
        Semantics(
          label: widget.label,
          child: SearchAnchor(
            searchController: _controller,
            viewHintText: widget.hintText,
            builder: (BuildContext context, SearchController controller) {
              return SearchBar(
                controller: controller,
                hintText: widget.hintText,
                leading: const Icon(Icons.search_rounded),
                trailing: isSelected
                    ? [
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          tooltip: context.l10n.journeySearchClearStop(
                            widget.label,
                          ),
                          onPressed: () {
                            controller.clear();
                            widget.onStopSelected(null);
                          },
                        ),
                      ]
                    : null,
                onTap: () {
                  controller.clear();
                  controller.openView();
                },
                onChanged: (_) {
                  controller.openView();
                },
              );
            },
            suggestionsBuilder:
                (BuildContext context, SearchController controller) {
                  final query = controller.text;
                  final searchAsync = ref.read(
                    stopSearchProvider(
                      StopSearchQuery(
                        query: query,
                        excludedStopId: widget.excludedStopId,
                      ),
                    ),
                  );

                  return searchAsync.when(
                    data: (stops) {
                      if (stops.isEmpty) {
                        return [
                          Padding(
                            padding: const EdgeInsets.all(GtSpacing.lg),
                            child: Center(
                              child: Text(
                                context.l10n.journeySearchNoStopsFound,
                                style: textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ];
                      }

                      return stops.map((stop) {
                        return ListTile(
                          key: ValueKey('stop_suggestion_${stop.id.value}'),
                          title: Text(stop.name.english),
                          onTap: () {
                            controller.closeView(stop.name.english);
                            widget.onStopSelected(stop.id);
                          },
                        );
                      });
                    },
                    loading: () => const [
                      Padding(
                        padding: EdgeInsets.all(GtSpacing.lg),
                        child: GtLoadingView(),
                      ),
                    ],
                    error: (error, _) => [
                      Padding(
                        padding: const EdgeInsets.all(GtSpacing.lg),
                        child: Center(
                          child: Text(
                            context.l10n.errorUnexpected,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
          ),
        ),
      ],
    );
  }
}
