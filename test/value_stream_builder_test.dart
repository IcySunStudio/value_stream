import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:value_stream/value_stream.dart';

void main() {
  group('DataValueStreamBuilder', () {
    testWidgets('Widget is rebuilt with new stream value when it is updated', (WidgetTester tester) async {
      final vs = DataValueStream(1);

      await tester.pumpWidget(MaterialApp(
        home: DataValueStreamBuilder<int>(
          stream: vs,
          builder: (context, value) => Text('$value'),
        ),
      ));
      expect(find.text('1'), findsOneWidget);

      vs.add(2);
      await tester.pump();
      expect(find.text('2'), findsOneWidget);

      vs.close();
    });
  });

  // TODO EventValueStreamBuilder
}
