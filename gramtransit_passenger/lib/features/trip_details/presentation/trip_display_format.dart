import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/l10n/date_time_formatting.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';

/// Formatted representation of a [ServiceTime] containing its localized clock
/// time string and whether it operates on the next calendar day (>= 24:00).
class FormattedServiceTime {
  const FormattedServiceTime({
    required this.clockTime,
    required this.isNextDay,
  });

  /// Localized clock time formatted with the user's 12-hour or 24-hour preference.
  final String clockTime;

  /// Whether the service time has hour >= 24, indicating departure/arrival on the next day.
  final bool isNextDay;
}

/// Resolves a [LocalizedText] into a passenger-facing string for Trip Details.
///
/// Phase 1 ships English UI only, returning [LocalizedText.english].
/// When multilingual UI is introduced, this helper will be updated or promoted.
String resolveLocalizedText(LocalizedText text, [BuildContext? context]) {
  return text.english;
}

/// Formats [ServiceDays] into a localized passenger-facing string.
///
/// Returns "Runs every day" when all seven days are true.
/// Otherwise returns "Runs {days}" with Monday-first ordered, comma-separated short weekday names.
String formatServiceDays(BuildContext context, ServiceDays days) {
  final l10n = context.l10n;
  final allDays =
      days.monday &&
      days.tuesday &&
      days.wednesday &&
      days.thursday &&
      days.friday &&
      days.saturday &&
      days.sunday;

  if (allDays) {
    return l10n.tripDetailsRunsEveryDay;
  }

  final activeDays = <String>[];
  if (days.monday) activeDays.add(formatShortWeekday(context, DateTime.monday));
  if (days.tuesday) {
    activeDays.add(formatShortWeekday(context, DateTime.tuesday));
  }
  if (days.wednesday) {
    activeDays.add(formatShortWeekday(context, DateTime.wednesday));
  }
  if (days.thursday) {
    activeDays.add(formatShortWeekday(context, DateTime.thursday));
  }
  if (days.friday) activeDays.add(formatShortWeekday(context, DateTime.friday));
  if (days.saturday) {
    activeDays.add(formatShortWeekday(context, DateTime.saturday));
  }
  if (days.sunday) activeDays.add(formatShortWeekday(context, DateTime.sunday));

  return l10n.tripDetailsRunsOn(activeDays.join(', '));
}

/// Formats a [ServiceTime] for presentation, normalizing hours >= 24 into [0..23]
/// and indicating [FormattedServiceTime.isNextDay].
FormattedServiceTime formatServiceTime(
  BuildContext context,
  ServiceTime serviceTime,
) {
  final isNextDay = serviceTime.hour >= 24;
  final normalizedHour = serviceTime.hour % 24;
  final timeOfDay = TimeOfDay(hour: normalizedHour, minute: serviceTime.minute);
  final clockTime = formatClockTime(context, timeOfDay);

  return FormattedServiceTime(clockTime: clockTime, isNextDay: isNextDay);
}
