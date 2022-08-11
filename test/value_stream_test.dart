import 'package:flutter_test/flutter_test.dart';

import 'package:value_stream/value_stream.dart';

void main() {
  group('ValueStream', () {
    test('takes initialValue', () {
      final sv = ValueStream(42);
      expect(sv.value, 42);
      sv.close();
    });

    test('updates value on add()', () {
      final sv = ValueStream(42);
      expect(sv.value, 42);

      sv.add(43);
      expect(sv.value, 43);

      sv.close();
    });

    test('only latest value', () {
      final sv = ValueStream(1);

      sv.add(2);
      sv.add(3);
      sv.add(4);
      expect(sv.value, 4);

      sv.close();
    });

    test('works with nullables', () {
      final sv = ValueStream<int?>(null);
      expect(sv.value, isNull);

      sv.add(45);
      expect(sv.value, 45);

      sv.add(null);
      expect(sv.value, isNull);

      sv.add(48);
      expect(sv.value, 48);

      sv.close();
    });

    test('isClosed set after close()', () {
      final sv = ValueStream(42);
      expect(sv.isClosed, isFalse);

      sv.close();
      expect(sv.isClosed, isTrue);
    });

    test('listen() push updates', () async {
      final sv = ValueStream(0);
      expect(sv.value, 0);

      final values = <int>[];
      final ss = sv.listen(values.add);

      sv.add(1);
      sv.add(2);
      sv.add(3);

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 2, 3]);
      expect(sv.value, 3);

      ss.cancel();
      sv.close();
    });

    test('add() arguments', () async {
      final sv = ValueStream<int?>(0);
      expect(sv.value, 0);

      final values = <int?>[];
      final ss = sv.listen(values.add);

      sv.add(1);
      sv.add(1);
      sv.add(1, skipSame: true);
      sv.add(1);

      sv.add(null);
      sv.add(null, skipNull: true);
      sv.add(null);

      sv.add(2, skipIfClosed: true);
      sv.add(3, skipIfClosed: true, skipNull: true, skipSame: true);

      sv.close();
      expect(sv.add(4, skipIfClosed: true), isFalse);
      expect(() => sv.add(4), throwsA(isA<Error>()));

      await Future.delayed(const Duration(milliseconds: 1));
      expect(values, [1, 1, 1, null, null, 2, 3]);
      expect(sv.value, 3);

      ss.cancel();
      sv.close();
    });
  });
}
