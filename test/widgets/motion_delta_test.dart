import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/motion_number.dart';

Widget host(Widget child, {MotionNumberTheme? theme}) => MaterialApp(
  theme: ThemeData(extensions: <ThemeExtension<dynamic>>[?theme]),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('label', () {
    test('formats a rise with a plus sign', () {
      expect(
        MotionDelta.label(ValueTransition.between(124350, 131890)),
        '+6.06%',
      );
    });

    test('formats a fall with a minus sign', () {
      expect(MotionDelta.label(ValueTransition.between(200, 150)), '-25.00%');
    });

    test('honours decimalDigits', () {
      expect(
        MotionDelta.label(
          ValueTransition.between(124350, 131890),
          decimalDigits: 1,
        ),
        '+6.1%',
      );
    });

    test('falls back to the absolute delta when from is zero', () {
      // Percent change from zero is undefined, so showing "+100%" would lie.
      expect(MotionDelta.label(ValueTransition.between(0, 500)), '+500');
    });

    test('renders an unchanged value without a sign', () {
      expect(MotionDelta.label(ValueTransition.between(5, 5)), '0.00%');
    });
  });

  group('arrows and spoken labels', () {
    test('arrows follow direction', () {
      expect(MotionDelta.arrowFor(MotionDirection.up), '↑');
      expect(MotionDelta.arrowFor(MotionDirection.down), '↓');
      expect(MotionDelta.arrowFor(MotionDirection.none), '');
    });

    test('speaks direction as a word, never as a glyph', () {
      final String spoken = MotionDelta.semanticLabelFor(
        ValueTransition.between(124350, 131890),
      );

      expect(spoken, 'up 6.06 percent');
      expect(spoken, isNot(contains('↑')));
    });

    test('speaks a fall as down', () {
      expect(
        MotionDelta.semanticLabelFor(ValueTransition.between(200, 150)),
        'down 25.00 percent',
      );
    });

    test('speaks an unchanged value plainly', () {
      expect(
        MotionDelta.semanticLabelFor(ValueTransition.between(5, 5)),
        'unchanged',
      );
    });
  });

  group('widget', () {
    testWidgets('renders nothing without a scope or transition', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const MotionDelta()));

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('renders an explicit transition', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(MotionDelta(transition: ValueTransition.between(100, 150))),
      );

      expect(find.text('↑ +50.00%'), findsOneWidget);
    });

    testWidgets('omits the arrow when asked', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          MotionDelta(
            transition: ValueTransition.between(100, 150),
            showArrow: false,
          ),
        ),
      );

      expect(find.text('+50.00%'), findsOneWidget);
    });

    testWidgets('reads a transition published by a sibling MotionNumber', (
      WidgetTester tester,
    ) async {
      Widget build(num value) => host(
        MotionNumberScope(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              MotionNumber(value: value),
              const MotionDelta(),
            ],
          ),
        ),
      );

      await tester.pumpWidget(build(124350));
      await tester.pumpWidget(build(131890));
      await tester.pumpAndSettle();

      expect(find.text('↑ +6.06%'), findsOneWidget);
    });

    testWidgets('applies direction colours', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          MotionDelta(
            transition: ValueTransition.between(200, 150),
            directionColors: const DirectionColors.greenUp(),
          ),
        ),
      );

      final Text text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, const Color(0xFFB91C1C));
    });

    testWidgets('deltaBuilder replaces the default rendering', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          MotionDelta(
            transition: ValueTransition.between(100, 150),
            deltaBuilder: (BuildContext context, ValueTransition t) =>
                Text('custom ${t.delta}'),
          ),
        ),
      );

      expect(find.text('custom 50'), findsOneWidget);
    });

    testWidgets('announces words rather than the arrow glyph', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        host(MotionDelta(transition: ValueTransition.between(100, 150))),
      );

      expect(find.bySemanticsLabel('up 50.00 percent'), findsOneWidget);
      handle.dispose();
    });
  });

  group('MotionNumberTheme', () {
    testWidgets('supplies default direction colours to MotionDelta', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          MotionDelta(transition: ValueTransition.between(100, 150)),
          theme: const MotionNumberTheme(
            directionColors: DirectionColors.greenUp(),
          ),
        ),
      );

      final Text text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, const Color(0xFF15803D));
    });

    testWidgets('an explicit argument beats the theme', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          MotionDelta(
            transition: ValueTransition.between(100, 150),
            directionColors: const DirectionColors.redUp(),
          ),
          theme: const MotionNumberTheme(
            directionColors: DirectionColors.greenUp(),
          ),
        ),
      );

      final Text text = tester.widget<Text>(find.byType(Text));
      expect(text.style?.color, const Color(0xFFB91C1C));
    });

    testWidgets('supplies a default style to MotionNumber', (
      WidgetTester tester,
    ) async {
      const MotionNumberTheme theme = MotionNumberTheme(
        style: NumberMotionStyle.slotMachine,
      );

      await tester.pumpWidget(host(const MotionNumber(value: 1), theme: theme));
      await tester.pumpWidget(host(const MotionNumber(value: 9), theme: theme));
      await tester.pump(const Duration(milliseconds: 50));

      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });

    test('lerp snaps discrete fields and interpolates colours', () {
      const MotionNumberTheme a = MotionNumberTheme(
        style: NumberMotionStyle.rolling,
        directionColors: DirectionColors.greenUp(),
      );
      const MotionNumberTheme b = MotionNumberTheme(
        style: NumberMotionStyle.flip,
        directionColors: DirectionColors.redUp(),
      );

      expect(a.lerp(b, 0.2).style, NumberMotionStyle.rolling);
      expect(a.lerp(b, 0.8).style, NumberMotionStyle.flip);
      expect(a.lerp(b, 0.5).directionColors, isNot(a.directionColors));
    });

    test('copyWith and equality behave', () {
      const MotionNumberTheme a = MotionNumberTheme(
        style: NumberMotionStyle.wave,
      );

      expect(a.copyWith(), a);
      expect(a.copyWith(style: NumberMotionStyle.flip), isNot(a));
    });
  });
}
