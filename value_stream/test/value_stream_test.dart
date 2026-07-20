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

    test('where() returns DataStreamView of nullable type', () async {
      final vs = DataStream<int>(10);
      final filtered = vs.where((v) => v > 5);

      expect(filtered, isA<DataStreamView<int?>>());
      expect(filtered.value, 10); // passes predicate

      final values = <int?>[];
      final ss = filtered.listen(values.add);

      vs.add(8);  // passes
      vs.add(3);  // fails → null
      vs.add(7);  // passes

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [8, null, 7]);

      ss.cancel();
      vs.close();
    });

    test('where() initial value fails predicate → null', () {
      final vs = DataStream<int>(2);
      final filtered = vs.where((v) => v > 5);
      expect(filtered.value, isNull);
      vs.close();
    });

    test('where() close propagates to result', () async {
      final vs = DataStream<int>(10);
      final filtered = vs.where((v) => v > 5);
      vs.close();
      await Future.delayed(const Duration(milliseconds: 1));
      expect(filtered.isClosed, isTrue);
    });

    test('asView returns DataStreamView, hides write interface', () {
      final vs = DataStream<int>(42);
      final DataStreamView<int> view = vs.asView; // static type is DataStreamView
      expect(view.value, 42);
      vs.add(99);
      expect(view.value, 99); // view reflects live updates
      vs.close();
    });

    test('map() returns DataStreamView with converted value', () async {
      final vs = DataStream<int>(10);
      final mapped = vs.map((v) => 'n=$v');

      expect(mapped, isA<DataStreamView<String>>());
      expect(mapped.value, 'n=10');

      final values = <String>[];
      final ss = mapped.listen(values.add);

      vs.add(20);
      vs.add(30);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, ['n=20', 'n=30']);
      expect(mapped.value, 'n=30');

      ss.cancel();
      vs.close();
    });

    test('map() is lazy: no subscription until listened', () async {
      final vs = DataStream<int>(1);
      final mapped = vs.map((v) => v * 2);

      // Emit before any listener — value is snapshotted at map() time and
      // stays stale until the first listener attaches.
      vs.add(5);
      await Future.delayed(const Duration(milliseconds: 1));
      // Before any listener: still reflects the snapshot at map() creation (1*2=2).
      expect(mapped.value, 2);

      vs.close();
    });

    test('map() eager snapshot: stale value corrected on first listen', () async {
      final vs = DataStream<int>(1);
      final mapped = vs.map((v) => v * 2);

      vs.add(5); // source advances while no one is listening
      expect(mapped.value, 2); // still stale before listen

      // Attaching the first listener triggers an eager re-snapshot.
      final ss = mapped.listen(null);
      expect(mapped.value, 10); // corrected: convert(5) = 10

      ss.cancel();
      vs.close();
    });

    test('map() eager snapshot: stale value corrected on re-listen after cancel', () async {
      final vs = DataStream<int>(1);
      final mapped = vs.map((v) => v * 2);

      // First listen cycle.
      final ss1 = mapped.listen(null);
      vs.add(3);
      await Future.delayed(const Duration(milliseconds: 1));
      expect(mapped.value, 6);
      ss1.cancel(); // unsubscribes from source

      // Source advances while unlistened.
      vs.add(7);
      expect(mapped.value, 6); // still stale after cancel

      // Re-listening triggers a fresh eager re-snapshot.
      final ss2 = mapped.listen(null);
      expect(mapped.value, 14); // corrected: convert(7) = 14

      ss2.cancel();
      vs.close();
    });

    test('map() auto-closes when source closes', () async {
      final vs = DataStream<int>(1);
      final mapped = vs.map((v) => v * 2);

      final ss = mapped.listen(null);
      vs.close();

      await Future.delayed(const Duration(milliseconds: 1));
      expect(mapped.isClosed, isTrue);
      ss.cancel();
    });

    test('map() can be chained', () async {
      final vs = DataStream<int>(3);
      final chained = vs.map((v) => v * 2).map((v) => '$v!');

      expect(chained.value, '6!');

      final values = <String>[];
      final ss = chained.listen(values.add);

      vs.add(5);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, ['10!']);

      ss.cancel();
      vs.close();
    });

    test('map() is callable on ValueStreamView typed variable', () async {
      final DataStream<int> vs = DataStream<int>(10);
      final ValueStreamView<int> view = vs.asView;
      final ValueStreamView<String> mapped = view.map((v) => 'n=$v');

      expect(mapped.valueOrNull, 'n=10');

      final values = <String>[];
      final ss = mapped.listen(values.add);

      vs.add(20);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, ['n=20']);

      ss.cancel();
      vs.close();
    });
  });
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

    test('add() arguments', () async {
      final es = EventStream<int?>(0);
      expect(es.valueOrNull, 0);

      final values = <int?>[];
      final ss = es.listen(values.add);

      es.add(1);
      es.add(1);
      es.add(1, skipSame: true);
      es.add(1);

      es.add(null);
      es.add(null, skipNull: true);
      es.add(null);

      es.add(2, skipIfClosed: true);
      es.add(3, skipIfClosed: true, skipNull: true, skipSame: true);

      es.close();
      expect(es.add(4, skipIfClosed: true), isFalse);
      expect(() => es.add(4), throwsA(isA<Error>()));

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 1, 1, null, null, 2, 3]);
      expect(es.valueOrNull, 3);

      ss.cancel();
      es.close();
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
      final es = EventStream<int>();
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
      final es = EventStream();
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

    test('where() returns EventStreamView of nullable type', () async {
      final es = EventStream<int>(10);
      final filtered = es.where((v) => v > 5);

      expect(filtered, isA<EventStreamView<int?>>());
      expect(filtered.valueOrNull, 10); // passes predicate

      final values = <int?>[];
      final ss = filtered.listen(values.add);

      es.add(8);  // passes
      es.add(3);  // fails → null
      es.add(7);  // passes

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [8, null, 7]);

      ss.cancel();
      es.close();
    });

    test('where() initial value fails predicate → null', () {
      final es = EventStream<int>(2);
      final filtered = es.where((v) => v > 5);
      expect(filtered.valueOrNull, isNull);
      es.close();
    });

    test('where() with no initial value', () {
      final es = EventStream<int>();
      final filtered = es.where((v) => v > 5);
      expect(filtered.valueOrNull, isNull);
      expect(filtered.hasValue, isFalse);
      es.close();
    });

    test('map() returns EventStreamView with converted value', () async {
      final es = EventStream<int>(10);
      final mapped = es.map((v) => 'n=$v');

      expect(mapped, isA<EventStreamView<String>>());
      expect(mapped.valueOrNull, 'n=10');

      final values = <String>[];
      final ss = mapped.listen(values.add);

      es.add(20);
      es.add(30);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, ['n=20', 'n=30']);
      expect(mapped.valueOrNull, 'n=30');

      ss.cancel();
      es.close();
    });

    test('map() forwards errors', () async {
      final es = EventStream<int>();
      final mapped = es.map((v) => v * 2);

      Object? caughtError;
      final ss = mapped.listen(null, onError: (e) => caughtError = e);

      final err = Error();
      es.addError(err);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(caughtError, same(err));
      expect(mapped.hasError, isTrue);

      ss.cancel();
      es.close();
    });

    test('map() with no initial value → no initial mapped value', () {
      final es = EventStream<int>();
      final mapped = es.map((v) => v * 2);
      expect(mapped.valueOrNull, isNull);
      expect(mapped.hasValue, isFalse);
      es.close();
    });

    test('map() auto-closes when source closes', () async {
      final es = EventStream<int>(1);
      final mapped = es.map((v) => v * 2);

      final ss = mapped.listen(null);
      es.close();

      await Future.delayed(const Duration(milliseconds: 1));
      expect(mapped.isClosed, isTrue);
      ss.cancel();
    });

    test('map() can be chained', () async {
      final es = EventStream<int>(3);
      final chained = es.map((v) => v * 2).map((v) => '$v!');

      expect(chained.valueOrNull, '6!');

      final values = <String>[];
      final ss = chained.listen(values.add);

      es.add(5);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, ['10!']);

      ss.cancel();
      es.close();
    });

    test('map() eager snapshot: stale value corrected on first listen', () async {
      final es = EventStream<int>(1);
      final mapped = es.map((v) => v * 2);

      es.add(5); // source advances while no one is listening
      expect(mapped.valueOrNull, 2); // still stale before listen

      // Attaching the first listener triggers an eager re-snapshot.
      final ss = mapped.listen(null);
      expect(mapped.valueOrNull, 10); // corrected: convert(5) = 10

      ss.cancel();
      es.close();
    });

    test('map() eager snapshot: stale error corrected on first listen', () async {
      final es = EventStream<int>(1);
      final mapped = es.map((v) => v * 2);

      final err = Error();
      es.addError(err); // source advances to error state while no one is listening
      expect(mapped.hasError, isFalse); // still stale before listen

      // Attaching the first listener triggers an eager re-snapshot of the error.
      final ss = mapped.listen(null, onError: (_) {});
      expect(mapped.hasError, isTrue);
      expect(mapped.error, same(err));

      ss.cancel();
      es.close();
    });

    test('asView returns EventStreamView, hides write interface', () {
      final es = EventStream<int>(42);
      final EventStreamView<int> view = es.asView; // static type is EventStreamView
      expect(view.valueOrNull, 42);
      es.add(99);
      expect(view.valueOrNull, 99); // view reflects live updates
      es.close();
    });
  });
}
