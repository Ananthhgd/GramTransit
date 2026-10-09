import 'package:flutter_test/flutter_test.dart';

import 'package:gramtransit_passenger/core/storage/in_memory_key_value_store.dart';

void main() {
  group('InMemoryKeyValueStore', () {
    late InMemoryKeyValueStore store;

    setUp(() => store = InMemoryKeyValueStore());

    test('returns null for missing key', () {
      expect(store.getString('missing'), isNull);
    });

    test('stores and retrieves a string', () async {
      await store.setString('key', 'value');
      expect(store.getString('key'), equals('value'));
    });

    test('overwrites existing value', () async {
      await store.setString('key', 'first');
      await store.setString('key', 'second');
      expect(store.getString('key'), equals('second'));
    });

    test('remove deletes a key', () async {
      await store.setString('key', 'value');
      await store.remove('key');
      expect(store.getString('key'), isNull);
    });

    test('remove on missing key is a no-op', () async {
      // Should not throw.
      await expectLater(store.remove('nonexistent'), completes);
    });

    test('seeded initial values are available immediately', () {
      final seeded = InMemoryKeyValueStore(
        initial: {'gt.settings.theme_mode': 'dark'},
      );
      expect(seeded.getString('gt.settings.theme_mode'), equals('dark'));
    });

    test('seeded initial map is copied — mutations do not affect original', () {
      final initial = {'key': 'value'};
      final seeded = InMemoryKeyValueStore(initial: initial);
      initial['key'] = 'mutated';
      expect(seeded.getString('key'), equals('value'));
    });
  });

  group('FailingKeyValueStore', () {
    late FailingKeyValueStore store;

    setUp(() => store = const FailingKeyValueStore());

    test('getString always returns null', () {
      expect(store.getString('any'), isNull);
    });

    test('setString throws StorageFailure', () async {
      await expectLater(
        store.setString('key', 'value'),
        throwsA(isA<Object>()),
      );
    });

    test('remove throws StorageFailure', () async {
      await expectLater(store.remove('key'), throwsA(isA<Object>()));
    });
  });
}
