import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/design_system/tokens/gt_spacing.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/home/presentation/home_display_format.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';
import 'package:gramtransit_passenger/features/transit/domain/transit_models.dart';

/// Accessible Material 3 stop selection dropdown for the Home screen.
class HomeStopSelector extends StatelessWidget {
  const HomeStopSelector({
    super.key,
    required this.stops,
    required this.selectedStopId,
    required this.onStopSelected,
  });

  final List<TransitStop> stops;
  final StopId? selectedStopId;
  final ValueChanged<StopId?> onStopSelected;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = stops.any((s) => s.id == selectedStopId)
        ? selectedStopId
        : null;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: context.l10n.homeStopSelectorLabel,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: GtSpacing.md,
          vertical: GtSpacing.xs,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<StopId>(
          value: effectiveValue,
          isExpanded: true,
          isDense: true,
          items: stops.map((stop) {
            return DropdownMenuItem<StopId>(
              value: stop.id,
              child: Text(
                resolveLocalizedText(stop.name, context),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onStopSelected,
        ),
      ),
    );
  }
}
