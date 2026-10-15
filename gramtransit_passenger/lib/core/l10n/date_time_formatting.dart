import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Feature-agnostic date and time formatting utilities.
///
/// These helpers encapsulate standard Flutter and intl localization calls
/// so feature presentation layers do not duplicate locale-aware date/time logic.

/// Formats a [TimeOfDay] into a localized clock time string.
///
/// Respects the user's 24-hour or 12-hour time preference from [MediaQuery].
String formatClockTime(BuildContext context, TimeOfDay timeOfDay) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    timeOfDay,
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}

/// Formats a [DateTime] into a localized short date string (e.g. "Wed, Oct 14").
String formatShortDate(BuildContext context, DateTime dateTime) {
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.MMMEd(locale).format(dateTime);
}

/// Formats a weekday integer (1 for Monday through 7 for Sunday) into a localized
/// short weekday string (e.g. "Mon").
///
/// Throws an [ArgumentError] if [weekday] is not between 1 and 7.
String formatShortWeekday(BuildContext context, int weekday) {
  if (weekday < DateTime.monday || weekday > DateTime.sunday) {
    throw ArgumentError.value(
      weekday,
      'weekday',
      'Weekday must be between 1 (Monday) and 7 (Sunday)',
    );
  }
  final locale = Localizations.localeOf(context).toString();
  // Fixed reference week starting on Monday 2026-01-05
  final referenceDate = DateTime(2026, 1, 4 + weekday);
  return DateFormat.E(locale).format(referenceDate);
}
