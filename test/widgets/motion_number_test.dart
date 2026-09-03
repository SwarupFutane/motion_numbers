import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/src/core/value_transition.dart';
import 'package:motion_number/src/formatting/plain_formatter.dart';
import 'package:motion_number/src/widgets/digit_cell.dart';
import 'package:motion_number/src/widgets/motion_number.dart';
import 'package:motion_number/src/widgets/separator_cell.dart';

/// Wraps [child] in the minimum a widget needs to lay out and animate.
Widget host(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: DefaultTextStyle(
      style: const TextStyle(fontSize: 20),
      child: Center(child: child),
    ),
  ),
);

void main() {
  group('layout', () {
    testWidgets('renders one cell per glyph slot', (WidgetTester tester) async {
      await tester.pumpWidget(host(const MotionNumber(value: 1234)));

      // "1,234" is four digits and one separator.
      expect(find.byType(DigitCell), findsNWidgets(4));
      expect(find.byType(SeparatorCell), findsOneWidget);
    });

    testWidgets('gives every digit the same width', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const MotionNumber(value: 1811)));

      final Iterable<Size> sizes = tester
          .widgetList<DigitCell>(find.byType(DigitCell))
          .map((DigitCell cell) => cell.data.cellSize);

      expect(sizes.toSet(), hasLength(1), reason: '1 and 8 must match');
    });

    testWidgets('does not change width while animating', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const MotionNumber(value: 111)));
      final double before = tester.getSize(find.byType(Row).first).width;

      await tester.pumpWidget(host(const MotionNumber(value: 888)));
      await tester.pump(const Duration(milliseconds: 200));
      final double during = tester.getSize(find.byType(Row).first).width;

      expect(during, before, reason: 'the row must not reflow mid-animation');
      await tester.pumpAndSettle();
    });

    testWidgets('uses the supplied formatter', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(
          const MotionNumber(
            value: 1234,
            formatter: PlainFormatter(grouped: false),
          ),
        ),
      );

      expect(find.byType(SeparatorCell), findsNothing);
      expect(find.byType(DigitCell), findsNWidgets(4));
    });
  });

  group('bug 1 — the digit count changes', () {
    testWidgets('999 -> 1000 adds exactly one digit cell', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MotionNumber(
            value: 999,
            formatter: PlainFormatter(grouped: false),
          ),
        ),
      );
      expect(find.byType(DigitCell), findsNWidgets(3));

      await tester.pumpWidget(
        host(
          const MotionNumber(
            value: 1000,
            formatter: PlainFormatter(grouped: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.byType(DigitCell), findsNWidgets(4));
      await tester.pumpAndSettle();
    });

    testWidgets('the entering digit widens from nothing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MotionNumber(
            value: 999,
            formatter: PlainFormatter(grouped: false),
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          const MotionNumber(
            value: 1000,
            formatter: PlainFormatter(grouped: false),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 1));

      final DigitCell leading = tester.widget<DigitCell>(
        find.byType(DigitCell).first,
      );
      expect(leading.widthFactor, lessThan(0.2));

      await tester.pump(const Duration(milliseconds: 400));
      final DigitCell later = tester.widget<DigitCell>(
        find.byType(DigitCell).first,
      );
      expect(later.widthFactor, greaterThan(leading.widthFactor));

      await tester.pumpAndSettle();
    });

    testWidgets('1000 -> 999 removes a digit once settled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(
          const MotionNumber(
            value: 1000,
            formatter: PlainFormatter(grouped: false),
          ),
        ),
      );
      await tester.pumpWidget(
        host(
          const MotionNumber(
            value: 999,
            formatter: PlainFormatter(grouped: false),
          ),
        ),
      );

      // The exiting slot is still rendered while it shrinks.
      await tester.pump(const Duration(milliseconds: 1));
      expect(find.byType(DigitCell), findsNWidgets(4));

      await tester.pumpAndSettle();
      final DigitCell exiting = tester.widget<DigitCell>(
        find.byType(DigitCell).first,
      );
      expect(exiting.widthFactor, lessThan(0.01));
    });

    testWidgets('a new grouping separator animates in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const MotionNumber(value: 999)));
      expect(find.byType(SeparatorCell), findsNothing);

      await tester.pumpWidget(host(const MotionNumber(value: 1000)));
      await tester.pump(const Duration(milliseconds: 1));

      expect(find.byType(SeparatorCell), findsOneWidget);
      final SeparatorCell separator = tester.widget<SeparatorCell>(
        find.byType(SeparatorCell),
      );
      expect(separator.widthFactor, lessThan(1.0));

      await tester.pumpAndSettle();
    });
  });

  group('bug 2 — interruption mid-animation', () {
    testWidgets('a value change mid-flight does not throw or stall', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const MotionNumber(value: 100)));
      await tester.pumpWidget(host(const MotionNumber(value: 200)));
      await tester.pump(const Duration(milliseconds: 200));

      // Interrupt halfway.
      await tester.pumpWidget(host(const MotionNumber(value: 300)));
      await tester.pump(const Duration(milliseconds: 1));

      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(find.byType(DigitCell), findsNWidgets(3));
    });

    testWidgets('restarts from zero rather than resuming', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const MotionNumber(value: 100)));
      await tester.pumpWidget(host(const MotionNumber(value: 200)));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(host(const MotionNumber(value: 300)));
      await tester.pump(const Duration(milliseconds: 1));

      // A freshly restarted controller leaves every slot near t = 0.
      final Iterable<DigitCell> cells = tester.widgetList<DigitCell>(
        find.byType(DigitCell),
      );
      expect(cells.every((DigitCell c) => c.t < 0.2), isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets('survives rapid successive updates', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(host(const MotionNumber(value: 0)));
      for (int i = 1; i <= 12; i++) {
        await tester.pumpWidget(host(MotionNumber(value: i * 137)));
        await tester.pump(const Duration(milliseconds: 30));
      }

      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
    });
  });

  group('bug 3 — disableAnimations', () {
    testWidgets('jumps straight to the final value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        host(const MotionNumber(value: 111), disableAnimations: true),
      );
      await tester.pumpWidget(
        host(const MotionNumber(value: 999), disableAnimations: true),
      );
      await tester.pump(const Duration(milliseconds: 1));

      // Every slot reports full progress on the very first frame.
      final Iterable<DigitCell> cells = tester.widgetList<DigitCell>(
        find.byType(DigitCell),
      );
      expect(cells.every((DigitCell c) => c.t == 1.0), isTrue);

      await tester.pumpAndSettle();
    });
  });

  group('bug 4 — semantics', () {
    testWidgets('announces the formatted number', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const MotionNumber(value: 1234)));

      expect(find.bySemanticsLabel('1,234'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('does not announce the 0-9 strips', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const MotionNumber(value: 5)));

      // Without ExcludeSemantics a screen reader would recite every digit in
      // every strip.
      expect(find.bySemanticsLabel('0'), findsNothing);
      expect(find.bySemanticsLabel('9'), findsNothing);
      handle.dispose();
    });

    testWidgets('updates the announcement when the value changes', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(host(const MotionNumber(value: 1234)));
      await tester.pumpWidget(host(const MotionNumber(value: 5678)));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('5,678'), findsOneWidget);
      expect(find.bySemanticsLabel('1,234'), findsNothing);
      handle.dispose();
    });
  });

  group('first build', () {
    testWidgets('does not animate by default', (WidgetTester tester) async {
      await tester.pumpWidget(host(const MotionNumber(value: 42)));

      final Iterable<DigitCell> cells = tester.widgetList<DigitCell>(
        find.byType(DigitCell),
      );
      expect(cells.every((DigitCell c) => c.t == 1.0), isTrue);
    });

    testWidgets('animates when asked to', (WidgetTester tester) async {
      await tester.pumpWidget(
        host(const MotionNumber(value: 42, animateOnFirstBuild: true)),
      );
      await tester.pump(const Duration(milliseconds: 1));

      final Iterable<DigitCell> cells = tester.widgetList<DigitCell>(
        find.byType(DigitCell),
      );
      expect(cells.any((DigitCell c) => c.t < 1.0), isTrue);

      await tester.pumpAndSettle();
    });
  });

  group('onTransition', () {
    testWidgets('reports the transition that just started', (
      WidgetTester tester,
    ) async {
      final List<ValueTransition> seen = <ValueTransition>[];

      await tester.pumpWidget(
        host(MotionNumber(value: 100, onTransition: seen.add)),
      );
      await tester.pumpWidget(
        host(MotionNumber(value: 250, onTransition: seen.add)),
      );
      await tester.pumpAndSettle();

      expect(seen, hasLength(1));
      expect(seen.single.from, 100);
      expect(seen.single.to, 250);
      expect(seen.single.percentChange, closeTo(150, 1e-9));
    });
  });
}
