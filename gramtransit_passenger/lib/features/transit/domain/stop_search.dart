import 'ids.dart';
import 'transit_models.dart';

/// Normalizes text for deterministic English stop search according to frozen rules:
/// 1. lowercase
/// 2. delete: . ' ’
/// 3. replace with space: - – / , ( )
/// 4. trim leading/trailing whitespace
/// 5. collapse repeated internal whitespace to one space
String normalizeStopSearch(String text) {
  var s = text.toLowerCase();
  s = s.replaceAll('.', '').replaceAll("'", '').replaceAll('’', '');
  s = s
      .replaceAll('-', ' ')
      .replaceAll('–', ' ')
      .replaceAll('/', ' ')
      .replaceAll(',', ' ')
      .replaceAll('(', ' ')
      .replaceAll(')', ' ');
  s = s.trim().replaceAll(RegExp(r'\s+'), ' ');
  return s;
}

/// Searches [timetable.stops] by matching English stop names against [query].
///
/// Supports an optional [excludedStopId] which will not be returned.
/// Preserves original timetable order when [query] is empty (or normalizes to empty).
/// When [query] is non-empty, matching stops are ranked into 4 stable buckets:
/// 1. exact normalized match
/// 2. normalized name starts with normalized query
/// 3. any word in normalized name starts with normalized query
/// 4. other substring match
///
/// Ties within each bucket preserve original timetable order.
List<TransitStop> searchStops({
  required Timetable timetable,
  required String query,
  StopId? excludedStopId,
}) {
  final normQuery = normalizeStopSearch(query);

  final candidateStops = timetable.stops.where((stop) {
    if (excludedStopId != null && stop.id == excludedStopId) {
      return false;
    }
    return true;
  });

  if (normQuery.isEmpty) {
    return List<TransitStop>.unmodifiable(candidateStops);
  }

  final bucket1 = <TransitStop>[];
  final bucket2 = <TransitStop>[];
  final bucket3 = <TransitStop>[];
  final bucket4 = <TransitStop>[];

  for (final stop in candidateStops) {
    final normName = normalizeStopSearch(stop.name.english);
    if (!normName.contains(normQuery)) {
      continue;
    }

    if (normName == normQuery) {
      bucket1.add(stop);
    } else if (normName.startsWith(normQuery)) {
      bucket2.add(stop);
    } else {
      final words = normName.split(' ');
      if (words.any((w) => w.startsWith(normQuery))) {
        bucket3.add(stop);
      } else {
        bucket4.add(stop);
      }
    }
  }

  return List<TransitStop>.unmodifiable([
    ...bucket1,
    ...bucket2,
    ...bucket3,
    ...bucket4,
  ]);
}
