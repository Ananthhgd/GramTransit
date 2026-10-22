import 'package:flutter/material.dart';

import 'package:gramtransit_passenger/core/l10n/date_time_formatting.dart';
import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';

/// Presentation formatting helpers scoped specifically to the Browse feature.
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

/// Resolves a [LocalizedText] into a passenger-facing string for display.
///
/// Phase 1 ships English UI only, returning [LocalizedText.english].
/// When multilingual UI is introduced, this helper will be updated or promoted.
String resolveLocalizedText(LocalizedText text, [BuildContext? context]) {
  return text.english;
}
