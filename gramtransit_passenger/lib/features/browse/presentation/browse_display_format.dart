import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/l10n/date_time_formatting.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_days.dart';
import 'package:gramtransit_passenger/features/transit/domain/service_time.dart';

/// Presentation formatting helpers scoped specifically to the Browse feature.
///
/// Converts domain types into localized display strings without embedding
/// presentation logic inside domain models.

/// Formatted representation of a [ServiceTime] endpoint containing its localized clock
/// time string and whether it operates on the next calendar day (hour >= 24).
class FormattedEndpointTime {
  const FormattedEndpointTime({
    required this.clockTime,
    required this.isNextDay,
  });

  /// Localized clock time formatted with the user's 12-hour or 24-hour preference.
  final String clockTime;

  /// Whether the service time has hour >= 24, indicating departure/arrival on the next day.
  final bool isNextDay;
}

/// Formats a [ServiceTime] endpoint for presentation, normalizing hours >= 24 into [0..23]
/// and indicating [FormattedEndpointTime.isNextDay].
FormattedEndpointTime formatServiceTime(
  BuildContext context,
  ServiceTime serviceTime,
) {
  final isNextDay = serviceTime.hour >= 24;
  final normalizedHour = serviceTime.hour % 24;
  final timeOfDay = TimeOfDay(hour: normalizedHour, minute: serviceTime.minute);
  final clockTime = formatClockTime(context, timeOfDay);

  return FormattedEndpointTime(clockTime: clockTime, isNextDay: isNextDay);
}

/// Formats [ServiceDays] into a localized passenger-facing string for Route Details.
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

  final weekdayInts = <int>[
    if (days.monday) DateTime.monday,
    if (days.tuesday) DateTime.tuesday,
    if (days.wednesday) DateTime.wednesday,
    if (days.thursday) DateTime.thursday,
    if (days.friday) DateTime.friday,
    if (days.saturday) DateTime.saturday,
    if (days.sunday) DateTime.sunday,
  ];

  final activeDays = formatShortWeekdays(context, weekdayInts);
  return l10n.tripDetailsRunsOn(activeDays.join(', '));
}

/// Formats a [DateTime] into a localized scheduled clock time string.
///
/// Respects the user's 24-hour or 12-hour time preference from [MediaQuery].
String formatScheduledTime(BuildContext context, DateTime dateTime) {
  return formatClockTime(context, TimeOfDay.fromDateTime(dateTime));
}

/// Formats a [DateTime] into a localized short date string (e.g. "Mon, Oct 14").
String formatDepartureDate(BuildContext context, DateTime dateTime) {
  return formatShortDate(context, dateTime);
}

/// Formats a [DateTime] for nextLater display containing date and clock time.
String formatNextLaterDeparture(BuildContext context, DateTime dateTime) {
  final date = formatDepartureDate(context, dateTime);
  final time = formatScheduledTime(context, dateTime);
  return '$date · $time';
}

/// Resolves a [LocalizedText] into a passenger-facing string for display.
///
/// Phase 1 ships English UI only, returning [LocalizedText.english].
/// When multilingual UI is introduced, this helper will be updated or promoted.
String resolveLocalizedText(LocalizedText text, [BuildContext? context]) {
  return text.english;
}
