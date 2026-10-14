import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:gramtransit_passenger/features/transit/domain/localized_text.dart';

/// Presentation formatting helpers scoped specifically to the Home feature.
///
/// Converts domain types into localized display strings without embedding
/// presentation logic inside domain models.

/// Formats a [DateTime] into a localized scheduled clock time string.
///
/// Respects the user's 24-hour or 12-hour time preference from [MediaQuery].
String formatScheduledTime(BuildContext context, DateTime dateTime) {
  final timeOfDay = TimeOfDay.fromDateTime(dateTime);
  return MaterialLocalizations.of(context).formatTimeOfDay(
    timeOfDay,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// Formats a [DateTime] into a localized short date string (e.g. "Mon, Oct 14").
String formatDepartureDate(BuildContext context, DateTime dateTime) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.MMMEd(locale).format(dateTime);
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
