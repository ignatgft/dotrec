import 'package:dotrec/core/theme/dot_theme.dart';
import 'package:dotrec/core/widgets/dot_widgets.dart';
import 'package:dotrec/core/widgets/record_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RecordButton имеет 6 визуальных состояний', (
    WidgetTester tester,
  ) async {
    for (final RecordVisualState v in RecordVisualState.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: DotTheme.dark(),
          home: Scaffold(
            body: RecordButton(visual: v, onTap: () {}),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(RecordButton), findsOneWidget);
    }
  });

  testWidgets('DotTimer форматирует мм:сс', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: DotTheme.light(),
        home: const Scaffold(body: DotTimer(elapsed: Duration(seconds: 42))),
      ),
    );
    expect(find.text('00:42'), findsOneWidget);
  });

  testWidgets('Палитра: светлая и тёмная темы строятся', (
    WidgetTester tester,
  ) async {
    for (final ThemeData t in [DotTheme.light(), DotTheme.dark()]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: t,
          home: Scaffold(
            body: Builder(
              builder: (BuildContext c) =>
                  Text('bg=${Theme.of(c).scaffoldBackgroundColor}'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Scaffold), findsOneWidget);
    }
  });
}
