import 'package:flutter_test/flutter_test.dart';

import 'package:value_stream/value_stream.dart';

void main() {
  group('ValueStream', () {
    test('takes initialValue', () {
      final vs = DataStream(42);
      expect(vs.value, 42);
      vs.close();
    });

    test('updates value on add()', () {
      final vs = DataStream(42);
      expect(vs.value, 42);

      vs.add(43);
      expect(vs.value, 43);

      vs.close();
    });

    test('only latest value', () {
      final vs = DataStream(1);

      vs.add(2);
      vs.add(3);
      vs.add(4);
      expect(vs.value, 4);

      vs.close();
    });

    test('works with nullables', () {
      final vs = DataStream<int?>(null);
      expect(vs.value, isNull);

      vs.add(45);
      expect(vs.value, 45);

      vs.add(null);
      expect(vs.value, isNull);

      vs.add(48);
      expect(vs.value, 48);

      vs.close();
    });

    test('isClosed set after close()', () {
      final vs = DataStream(42);
      expect(vs.isClosed, isFalse);

      vs.close();
      expect(vs.isClosed, isTrue);
    });

    test('listen() push updates', () async {
      final vs = DataStream(0);
      expect(vs.value, 0);

      final values = <int>[];
      final ss = vs.listen(values.add);

      vs.add(1);
      vs.add(2);
      vs.add(3);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 2, 3]);
      expect(vs.value, 3);

      ss.cancel();
      vs.close();
    });

    test('add() arguments', () async {
      final vs = DataStream<int?>(0);
      expect(vs.value, 0);

      final values = <int?>[];
      final ss = vs.listen(values.add);

      vs.add(1);
      vs.add(1);
      vs.add(1, skipSame: true);
      vs.add(1);

      vs.add(null);
      vs.add(null, skipNull: true);
      vs.add(null);

      vs.add(2, skipIfClosed: true);
      vs.add(3, skipIfClosed: true, skipNull: true, skipSame: true);

      vs.close();
      expect(vs.add(4, skipIfClosed: true), isFalse);
      expect(() => vs.add(4), throwsA(isA<Error>()));

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 1, 1, null, null, 2, 3]);
      expect(vs.value, 3);

      ss.cancel();
      vs.close();
    });
  });

  group('EventStream', () {
    test('takes initialValue', () {
      final vs = EventStream(42);
      expect(vs.valueOrNull, 42);
      vs.close();
    });

    test('updates value on add()', () {
      final vs = EventStream(42);
      expect(vs.valueOrNull, 42);

      vs.add(43);
      expect(vs.valueOrNull, 43);

      vs.close();
    });

    test('only latest value', () {
      final vs = EventStream(1);

      vs.add(2);
      vs.add(3);
      vs.add(4);
      expect(vs.valueOrNull, 4);

      vs.close();
    });

    test('works with nullables', () {
      final vs = EventStream<int?>(null);
      expect(vs.valueOrNull, isNull);

      vs.add(45);
      expect(vs.valueOrNull, 45);

      vs.add(null);
      expect(vs.valueOrNull, isNull);

      vs.add(48);
      expect(vs.valueOrNull, 48);

      vs.close();
    });

    test('isClosed set after close()', () {
      final vs = EventStream(42);
      expect(vs.isClosed, isFalse);

      vs.close();
      expect(vs.isClosed, isTrue);
    });

    test('listen() push updates', () async {
      final vs = EventStream(0);
      expect(vs.valueOrNull, 0);

      final values = <int>[];
      final ss = vs.listen(values.add);

      vs.add(1);
      vs.add(2);
      vs.add(3);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 2, 3]);
      expect(vs.valueOrNull, 3);

      ss.cancel();
      vs.close();
    });

    test('add() arguments', () async {
      final vs = EventStream<int?>(0);
      expect(vs.valueOrNull, 0);

      final values = <int?>[];
      final ss = vs.listen(values.add);

      vs.add(1);
      vs.add(1);
      vs.add(1, skipSame: true);
      vs.add(1);

      vs.add(null);
      vs.add(null, skipNull: true);
      vs.add(null);

      vs.add(2, skipIfClosed: true);
      vs.add(3, skipIfClosed: true, skipNull: true, skipSame: true);

      vs.close();
      expect(vs.add(4, skipIfClosed: true), isFalse);
      expect(() => vs.add(4), throwsA(isA<Error>()));

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 1, 1, null, null, 2, 3]);
      expect(vs.valueOrNull, 3);

      ss.cancel();
      vs.close();
    });

    test('updates error & value on addError() & add()', () {
      final vs = EventStream(42);
      expect(vs.valueOrNull, 42);

      vs.addError(Error());
      expect(vs.valueOrNull, isNull);
      expect(vs.error, isA<Error>());

      vs.add(100);
      expect(vs.valueOrNull, 100);
      expect(vs.error, isNull);

      vs.close();
    });
  });
}
