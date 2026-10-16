import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/l10n/date_time_formatting.dart';
import 'package:gramtransit_passenger/core/l10n/l10n_extensions.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';

/// Presentation formatting helpers scoped specifically to the Journey Search feature.
///
/// Converts domain types into localized display strings without embedding
/// presentation logic inside domain models.

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

/// Formats a journey [Duration] into a localized display string.
///
/// Explicitly handles [Duration.zero] as "Less than 1 min".
String formatJourneyDuration(BuildContext context, Duration duration) {
  if (duration == Duration.zero) {
    return context.l10n.journeyDurationLessThanOneMinute;
  }

  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours == 0) {
    return context.l10n.journeyDurationMinutes(minutes);
  } else if (minutes == 0) {
    return context.l10n.journeyDurationHours(hours);
  } else {
    return context.l10n.journeyDurationHoursMinutes(hours, minutes);
  }
}

/// Resolves a [LocalizedText] into a passenger-facing string for display.
///
/// Phase 2 ships English UI only, returning [LocalizedText.english].
/// When multilingual UI is introduced, this helper will be updated or promoted.
String resolveLocalizedText(LocalizedText text, [BuildContext? context]) {
  return text.english;
}
