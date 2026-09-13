import 'package:example/main.dart';
import 'package:example/ticker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/motion_number.dart';

/// Pumps the demo on a surface tall enough to build the whole of a screen.
///
/// Every screen is a scroll view, so on the default 800x600 test viewport the
/// controls below the fold are never built and a finder for them reports an
/// empty list rather than a layout problem.
Future<void> pumpDemo(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const MotionNumberDemo());
  await tester.pump();
}

/// A tab bar label. The large navigation title repeats the same text, so a
/// bare `find.text` would match both.
Finder tab(String label) => find.descendant(
  of: find.byType(CupertinoTabBar),
  matching: find.text(label),
);

void main() {
  group('DemoShell', () {
    testWidgets('opens on the gallery with all three tabs reachable', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      expect(tab('Gallery'), findsOneWidget);
      expect(tab('Portfolio'), findsOneWidget);
      expect(tab('Playground'), findsOneWidget);
      // The gallery's tour caption, so we know which tab is showing.
      expect(find.textContaining('A starting balance'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the tour advances a step at a time', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      expect(find.text('1 / 11'), findsOneWidget);
      await tester.tap(find.text('Next'));
      await tester.pump();
      expect(find.text('2 / 11'), findsOneWidget);
    });

    testWidgets('a style chosen in the gallery reaches the playground', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      await tester.tap(find.text('odometer'));
      await tester.pump();

      await tester.tap(tab('Playground'));
      await tester.pumpAndSettle();

      // Stagger is meaningless for odometer, so the slider says why.
      expect(find.text('odometer wheels share one shaft'), findsOneWidget);
      final CupertinoSlider stagger = tester.widget<CupertinoSlider>(
        find.byType(CupertinoSlider).last,
      );
      expect(stagger.onChanged, isNull);
    });

    testWidgets('the stagger slider is live for a style that has one', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      await tester.tap(tab('Playground'));
      await tester.pumpAndSettle();

      final CupertinoSlider stagger = tester.widget<CupertinoSlider>(
        find.byType(CupertinoSlider).last,
      );
      expect(stagger.onChanged, isNotNull);
      expect(stagger.value, const RollingMotion().staggerAmount);
      expect(tester.takeException(), isNull);
    });
  });

  group('PortfolioScreen', () {
    testWidgets('renders the holdings, each in its own scope', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      await tester.tap(tab('Portfolio'));
      await tester.pumpAndSettle();

      expect(find.text('ARLO'), findsOneWidget);
      expect(find.text('Portfolio value'), findsOneWidget);

      await tester.tap(find.text('Tick'));
      await tester.pump();

      // Each row sits under its own scope. A shared one would make every
      // delta on the screen show whichever row happened to publish last.
      Element scopeAround(String symbol) => tester.element(
        find.ancestor(
          of: find.text(symbol),
          matching: find.byType(MotionNumberScope),
        ),
      );
      expect(scopeAround('ARLO'), isNot(scopeAround('KVAN')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('Layout', () {
    testWidgets('every tab lays out on a small phone without overflow', (
      WidgetTester tester,
    ) async {
      // iPhone SE (3rd gen) logical size: the narrowest screen worth supporting.
      await tester.binding.setSurfaceSize(const Size(375, 667));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MotionNumberDemo());
      await tester.pump();

      for (final String label in <String>[
        'Gallery',
        'Portfolio',
        'Playground',
      ]) {
        await tester.tap(tab(label));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label overflowed');
      }
    });
  });

  group('PortfolioTicker', () {
    test('is deterministic for a given seed', () {
      final PortfolioTicker a = PortfolioTicker(seed: 42);
      final PortfolioTicker b = PortfolioTicker(seed: 42);
      for (int i = 0; i < 5; i++) {
        a.tick();
        b.tick();
      }
      expect(a.total, b.total);
      a.dispose();
      b.dispose();
    });

    test('starts stopped, and reset returns to the opening bell', () {
      final PortfolioTicker ticker = PortfolioTicker();
      expect(ticker.running, isFalse);

      final int open = ticker.total;
      ticker.tick();
      ticker.tick();
      expect(ticker.total, isNot(open));

      ticker.reset();
      expect(ticker.total, open);
      ticker.dispose();
    });
  });
}
