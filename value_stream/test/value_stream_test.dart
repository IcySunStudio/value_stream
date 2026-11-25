import 'dart:async';

import 'package:test/test.dart';

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

    test('add() is ignored when closed', () async {
      final vs = DataStream<int?>(0);
      expect(vs.value, 0);

      final values = <int?>[];
      final ss = vs.listen(values.add);

      vs.add(1);
      vs.add(1);
      vs.add(null);
      vs.add(null);
      vs.add(3);

      vs.close();
      expect(vs.add(4), isFalse);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 1, null, null, 3]);
      expect(vs.value, 3);

      ss.cancel();
    });

    test('distinct ignores values equal to the current one', () async {
      final vs = DataStream<int?>(0, distinct: true);
      expect(vs.distinct, isTrue);

      final values = <int?>[];
      final ss = vs.listen(values.add);

      expect(vs.add(0), isFalse);
      expect(vs.add(1), isTrue);
      expect(vs.add(1), isFalse);
      expect(vs.add(null), isTrue);
      expect(vs.add(null), isFalse);
      expect(vs.add(1), isTrue);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, null, 1]);
      expect(vs.value, 1);

      ss.cancel();
      vs.close();
    });

    test('values are not distinct by default', () async {
      final vs = DataStream(0);
      expect(vs.distinct, isFalse);
      expect(vs.add(0), isTrue);
      expect(vs.add(0), isTrue);
      vs.close();
    });

    test('first getter', () async {
      final vs = DataStream(42);
      final first = await vs.first;
      expect(first, 42);

      vs.close();
    });

    test('first getter returns null immediately for DataStream<int?> with null value', () async {
      final vs = DataStream<int?>(null);
      expect(vs.value, isNull);

      // Must resolve immediately without waiting for the next emission
      final first = await vs.first.timeout(const Duration(milliseconds: 100));
      expect(first, isNull);

      vs.close();
    });

    test('first getter returns null immediately for DataStream<int?> after emitting null', () async {
      final vs = DataStream<int?>(42);
      vs.add(null);

      final first = await vs.first.timeout(const Duration(milliseconds: 100));
      expect(first, isNull);

      vs.close();
    });

    test('next getter', () async {
      final vs = DataStream(42);
      var nextFuture = vs.next;
      vs.add(50);
      var next = await nextFuture;
      expect(next, 50);

      nextFuture = vs.next;
      vs.add(51);
      next = await nextFuture;
      expect(next, 51);

      vs.close();
    });

    test('fromStream', () async {
      final sc = StreamController<int>();
      final s = sc.stream;
      sc.add(0);

      final ds = DataStream.fromStream(s, 42);
      expect(ds.value, 42);

      sc.add(1);
      await Future.delayed(const Duration(milliseconds: 1));
      expect(ds.value, 1);

      ds.add(2);
      await Future.delayed(const Duration(milliseconds: 1));
      expect(ds.value, 2);

      sc.addError(Error());
      await Future.delayed(const Duration(milliseconds: 1));
      expect(ds.value, 2);

      ds.close();
      await Future.delayed(const Duration(milliseconds: 1));
      expect(ds.isClosed, isTrue);
      expect(sc.isClosed, isFalse);
    });

    test('fromStream with distinct', () async {
      final sc = StreamController<int>();
      final ds = DataStream.fromStream(sc.stream, 42, distinct: true);

      final values = <int>[];
      final ss = ds.listen(values.add);

      sc.add(42);
      sc.add(1);
      sc.add(1);
      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1]);

      ss.cancel();
      ds.close();
    });
  });

  group('EventStream', () {
    test('takes initialValue', () {
      final es = EventStream(42);
      expect(es.valueOrNull, 42);
      es.close();
    });

    test('updates value on add()', () {
      final es = EventStream(42);
      expect(es.valueOrNull, 42);

      es.add(43);
      expect(es.valueOrNull, 43);

      es.close();
    });

    test('only latest value', () {
      final es = EventStream(1);

      es.add(2);
      es.add(3);
      es.add(4);
      expect(es.valueOrNull, 4);

      es.close();
    });

    test('works with nullables', () {
      final es = EventStream<int?>(null);
      expect(es.valueOrNull, isNull);

      es.add(45);
      expect(es.valueOrNull, 45);

      es.add(null);
      expect(es.valueOrNull, isNull);

      es.add(48);
      expect(es.valueOrNull, 48);

      es.close();
    });

    test('isClosed set after close()', () {
      final es = EventStream(42);
      expect(es.isClosed, isFalse);

      es.close();
      expect(es.isClosed, isTrue);
    });

    test('listen() push updates', () async {
      final es = EventStream(0);
      expect(es.valueOrNull, 0);

      final values = <int>[];
      final ss = es.listen(values.add);

      es.add(1);
      es.add(2);
      es.add(3);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 2, 3]);
      expect(es.valueOrNull, 3);

      ss.cancel();
      es.close();
    });

    test('add() is ignored when closed', () async {
      final es = EventStream<int?>(0);
      expect(es.valueOrNull, 0);

      final values = <int?>[];
      final ss = es.listen(values.add);

      es.add(1);
      es.add(1);
      es.add(null);
      es.add(null);
      es.add(3);

      es.close();
      expect(es.add(4), isFalse);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 1, null, null, 3]);
      expect(es.valueOrNull, 3);

      ss.cancel();
    });

    test('distinct ignores values equal to the current one', () async {
      final es = EventStream<int?>(0, distinct: true);
      expect(es.distinct, isTrue);

      final values = <int?>[];
      final ss = es.listen(values.add);

      expect(es.add(0), isFalse);
      expect(es.add(1), isTrue);
      expect(es.add(1), isFalse);
      expect(es.add(null), isTrue);
      expect(es.add(null), isFalse);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, null]);

      ss.cancel();
      es.close();
    });

    test('distinct does not ignore null when stream is empty or in error', () {
      final es = EventStream<int?>.empty(distinct: true);
      expect(es.hasValue, isFalse);
      expect(es.add(null), isTrue);
      expect(es.add(null), isFalse);

      es.addError(Error());
      expect(es.hasValue, isFalse);
      expect(es.add(null), isTrue);
      expect(es.hasValue, isTrue);
      expect(es.hasError, isFalse);

      es.close();
    });

    test('empty has no value, unlike a nullable stream initialized with null', () {
      final empty = EventStream<int?>.empty();
      expect(empty.hasValue, isFalse);

      final withNull = EventStream<int?>(null);
      expect(withNull.hasValue, isTrue);
      expect(withNull.valueOrNull, isNull);

      empty.close();
      withNull.close();
    });

    test('add() and addError() are ignored on a closed stream', () {
      final es = EventStream(1);
      es.close();

      expect(es.add(2), isFalse);
      expect(es.valueOrNull, 1);

      es.addError(Error());
      expect(es.hasError, isFalse);
      expect(es.valueOrNull, 1);
    });

    test('updates error & value on addError() & add()', () {
      final es = EventStream(42);
      expect(es.valueOrNull, 42);

      es.addError(Error());
      expect(es.valueOrNull, isNull);
      expect(es.error, isA<Error>());

      es.add(100);
      expect(es.valueOrNull, 100);
      expect(es.error, isNull);

      es.close();
    });

    test('first getter waits for first emission when no initial value', () async {
      final es = EventStream<int>.empty();
      expect(es.valueOrNull, isNull);
      final firstFuture = es.first;
      es.add(42);
      final first = await firstFuture;
      expect(first, 42);

      es.add(50);
      expect(es.valueOrNull, 50);

      es.close();
    });

    test('first getter returns null immediately for EventStream<int?> with null initial value', () async {
      final es = EventStream<int?>(null);
      expect(es.valueOrNull, isNull);

      final first = await es.first.timeout(const Duration(milliseconds: 100));
      expect(first, isNull);

      es.close();
    });

    test('first getter returns null immediately for EventStream<int?> after emitting null', () async {
      final es = EventStream<int?>(42);
      es.add(null);

      final first = await es.first.timeout(const Duration(milliseconds: 100));
      expect(first, isNull);

      es.close();
    });

    test('next getter', () async {
      final es = EventStream<int>.empty();
      expect(es.valueOrNull, isNull);
      var nextFuture = es.next;
      es.add(42);
      var next = await nextFuture;
      expect(next, 42);

      nextFuture = es.next;
      es.add(50);
      next = await nextFuture;
      expect(next, 50);

      nextFuture = es.next;
      es.addError(Error());
      expect(() => nextFuture, throwsA(isA<Error>()));

      es.close();
    });

    test('fromStream', () async {
      final sc = StreamController<int>();
      final s = sc.stream;
      sc.add(0);

      final es = EventStream.fromStream(s);
      expect(es.valueOrNull, isNull);

      sc.add(1);
      await Future.delayed(const Duration(milliseconds: 1));
      expect(es.valueOrNull, 1);

      es.add(2);
      await Future.delayed(const Duration(milliseconds: 1));
      expect(es.valueOrNull, 2);

      sc.addError(Error());
      await Future.delayed(const Duration(milliseconds: 1));
      expect(es.valueOrNull, isNull);
      expect(es.error, isA<Error>());

      es.close();
      await Future.delayed(const Duration(milliseconds: 1));
      expect(es.isClosed, isTrue);
      expect(sc.isClosed, isFalse);
    });

    test('fromStream distinguishes an omitted initialValue from null', () {
      final omitted = EventStream<int?>.fromStream(const Stream.empty());
      expect(omitted.hasValue, isFalse);

      final withNull = EventStream<int?>.fromStream(const Stream.empty(), initialValue: null);
      expect(withNull.hasValue, isTrue);
      expect(withNull.valueOrNull, isNull);

      final withValue = EventStream<int>.fromStream(const Stream.empty(), initialValue: 3);
      expect(withValue.valueOrNull, 3);

      final nullOnNonNullable = EventStream<int>.fromStream(const Stream.empty(), initialValue: null);
      expect(nullOnNonNullable.hasValue, isFalse);

      omitted.close();
      withNull.close();
      withValue.close();
      nullOnNonNullable.close();
    });

    test('fromStream with distinct', () async {
      final sc = StreamController<int>();
      final es = EventStream.fromStream(sc.stream, initialValue: 42, distinct: true);
      expect(es.distinct, isTrue);

      final values = <int>[];
      final ss = es.listen(values.add);

      sc.add(42);
      sc.add(1);
      sc.add(1);
      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1]);

      ss.cancel();
      es.close();
    });
  });
}
