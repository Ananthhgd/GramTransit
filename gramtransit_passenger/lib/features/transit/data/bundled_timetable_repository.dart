// ignore_for_file: prefer_initializing_formals

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../core/error/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../domain/timetable_repository.dart';
import '../domain/transit_models.dart';
import 'timetable_dto.dart';
import 'timetable_format_exception.dart';
import 'timetable_mapper.dart';

class BundledTimetableRepository implements TimetableRepository {
  final AssetBundle _bundle;
  final AppLogger _logger;
  final String _assetPath;

  Timetable? _cachedTimetable;

  BundledTimetableRepository({
    required AssetBundle bundle,
    required AppLogger logger,
    String assetPath = 'assets/transit/timetable.json',
  }) : _bundle = bundle,
       _logger = logger,
       _assetPath = assetPath;

  @override
  Future<Timetable> loadTimetable() async {
    if (_cachedTimetable != null) {
      return _cachedTimetable!;
    }

    String assetString;
    try {
      assetString = await _bundle.loadString(_assetPath);
    } on FlutterError catch (e, st) {
      _logger.error(
        'Failed to load asset string for timetable',
        error: e,
        stackTrace: st,
      );
      throw DataFormatFailure(cause: e, stackTrace: st);
    } on FormatException catch (e, st) {
      _logger.error(
        'Format exception while loading asset string for timetable',
        error: e,
        stackTrace: st,
      );
      throw DataFormatFailure(cause: e, stackTrace: st);
    }

    Object? decodedJson;
    try {
      decodedJson = jsonDecode(assetString);
    } on FormatException catch (e, st) {
      _logger.error(
        'JSON format exception while decoding timetable',
        error: e,
        stackTrace: st,
      );
      throw DataFormatFailure(cause: e, stackTrace: st);
    }

    TimetableDto dto;
    try {
      dto = TimetableDto.fromJson(decodedJson);
    } on TimetableFormatException catch (e, st) {
      _logger.error(
        'DTO format exception while parsing timetable: ${e.path} - ${e.message}',
        error: e,
        stackTrace: st,
      );
      throw DataFormatFailure(cause: e, stackTrace: st);
    }

    Timetable timetable;
    try {
      timetable = TimetableMapper.toDomain(dto);
    } on TimetableFormatException catch (e, st) {
      _logger.error(
        'Mapper format exception for dataset ${dto.datasetVersion}: ${e.path} - ${e.message}',
        error: e,
        stackTrace: st,
      );
      throw DataFormatFailure(cause: e, stackTrace: st);
    }

    _cachedTimetable = timetable;
    return timetable;
  }
}
