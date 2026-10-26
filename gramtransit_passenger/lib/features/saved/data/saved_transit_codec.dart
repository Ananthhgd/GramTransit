import 'dart:convert';

import 'package:gramtransit_passenger/core/logging/app_logger.dart';
import 'package:gramtransit_passenger/features/saved/domain/saved_transit.dart';
import 'package:gramtransit_passenger/features/transit/domain/ids.dart';

/// Codec for serializing and deserializing [SavedTransit] to and from versioned JSON.
///
/// Follows a tolerant decode contract:
/// - Missing storage values return empty [SavedTransit] with no warning.
/// - Valid version 1 payloads decode stops and routes in stored order.
/// - Duplicate entries within a category retain only their first occurrence.
/// - Invalid individual elements (non-string, empty, whitespace-only) are dropped
///   while valid elements are preserved, and a warning summarizing dropped count is logged.
/// - Malformed envelopes (invalid JSON, non-object, missing/invalid version,
///   unsupported version, missing/invalid stops or routes lists) return empty
///   [SavedTransit] and log a diagnostic warning.
/// - Warnings never log raw persisted ID values or sensitive preference contents.
final class SavedTransitCodec {
  const SavedTransitCodec({this.logger = const AppLogger()});

  final AppLogger logger;

  static const int _currentVersion = 1;

  /// Encodes [savedTransit] to a version 1 JSON string.
  String encode(SavedTransit savedTransit) {
    final payload = <String, dynamic>{
      'version': _currentVersion,
      'stops': savedTransit.stopIds
          .map((id) => id.value)
          .toList(growable: false),
      'routes': savedTransit.routeIds
          .map((id) => id.value)
          .toList(growable: false),
    };
    return jsonEncode(payload);
  }

  /// Tolerantly decodes a raw JSON string into [SavedTransit].
  ///
  /// Returns an empty [SavedTransit] if [rawJson] is null or if the JSON
  /// envelope is malformed.
  SavedTransit decode(String? rawJson) {
    if (rawJson == null) {
      return const SavedTransit.empty();
    }

    final Object? decoded;
    try {
      decoded = jsonDecode(rawJson);
    } on FormatException {
      logger.warning(
        'Failed to decode saved transit preferences: invalid JSON',
      );
      return const SavedTransit.empty();
    }

    if (decoded is! Map) {
      logger.warning(
        'Failed to decode saved transit preferences: top level is not a JSON object',
      );
      return const SavedTransit.empty();
    }

    final version = decoded['version'];
    if (version == null || version is! int) {
      logger.warning(
        'Failed to decode saved transit preferences: missing or invalid version field',
      );
      return const SavedTransit.empty();
    }

    if (version != _currentVersion) {
      logger.warning(
        'Failed to decode saved transit preferences: unsupported version ($version)',
      );
      return const SavedTransit.empty();
    }

    final rawStops = decoded['stops'];
    if (rawStops is! List) {
      logger.warning(
        'Failed to decode saved transit preferences: missing or invalid stops list',
      );
      return const SavedTransit.empty();
    }

    final rawRoutes = decoded['routes'];
    if (rawRoutes is! List) {
      logger.warning(
        'Failed to decode saved transit preferences: missing or invalid routes list',
      );
      return const SavedTransit.empty();
    }

    final stopIds = <StopId>[];
    var droppedStops = 0;
    for (final item in rawStops) {
      if (item is! String) {
        droppedStops++;
        continue;
      }
      try {
        stopIds.add(StopId(item));
      } on ArgumentError {
        droppedStops++;
      }
    }
    if (droppedStops > 0) {
      logger.warning(
        'Ignored $droppedStops invalid stop entries from saved transit preferences',
      );
    }

    final routeIds = <RouteId>[];
    var droppedRoutes = 0;
    for (final item in rawRoutes) {
      if (item is! String) {
        droppedRoutes++;
        continue;
      }
      try {
        routeIds.add(RouteId(item));
      } on ArgumentError {
        droppedRoutes++;
      }
    }
    if (droppedRoutes > 0) {
      logger.warning(
        'Ignored $droppedRoutes invalid route entries from saved transit preferences',
      );
    }

    return SavedTransit(stopIds: stopIds, routeIds: routeIds);
  }
}
