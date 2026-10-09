import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/error/app_failure.dart';

void main() {
  group('toAppFailure', () {
    test('returns existing AppFailure unchanged', () {
      const failure = StorageFailure();
      final result = toAppFailure(failure, StackTrace.empty);
      expect(identical(result, failure), isTrue);
    });

    test('wraps arbitrary error in UnexpectedFailure', () {
      final error = Exception('boom');
      final st = StackTrace.current;
      final result = toAppFailure(error, st);
      expect(result, isA<UnexpectedFailure>());
      expect(result.cause, same(error));
      expect(result.stackTrace, same(st));
    });

    test('wraps a string error in UnexpectedFailure preserving cause', () {
      const error = 'something went wrong';
      final result = toAppFailure(error, StackTrace.empty);
      expect(result, isA<UnexpectedFailure>());
      expect(result.cause, equals(error));
    });
  });

  group('AppFailure subtypes', () {
    test('StorageFailure preserves cause and stack trace', () {
      final cause = Exception('disk full');
      final st = StackTrace.current;
      final failure = StorageFailure(cause: cause, stackTrace: st);
      expect(failure.cause, same(cause));
      expect(failure.stackTrace, same(st));
    });

    test('UnexpectedFailure preserves cause and stack trace', () {
      final cause = Error();
      final st = StackTrace.current;
      final failure = UnexpectedFailure(cause: cause, stackTrace: st);
      expect(failure.cause, same(cause));
      expect(failure.stackTrace, same(st));
    });

    test('const StorageFailure has null cause and null stackTrace', () {
      const failure = StorageFailure();
      expect(failure.cause, isNull);
      expect(failure.stackTrace, isNull);
    });
  });
}
