import 'package:example/main.dart';
import 'package:example/screens/record_screen.dart';
import 'package:example/ticker.dart';
import 'package:example/tuning.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/motion_number.dart';

/// Pumps the demo on a surface tall enough to build the whole of a screen.
///
/// Every screen is a `ListView`, so on the default 800x600 test viewport the
/// controls below the fold are never built and a finder for them reports an
/// empty list rather than a layout problem.
Future<void> pumpDemo(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1000, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(const MotionNumberDemo());
  await tester.pump();
}

void main() {
  group('DemoShell', () {
    testWidgets('opens on the gallery with all three tabs reachable', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      expect(find.text('Gallery'), findsOneWidget);
      expect(find.text('Portfolio'), findsOneWidget);
      expect(find.text('Playground'), findsOneWidget);
      // The gallery's tour caption, so we know which tab is showing.
      expect(find.textContaining('A starting balance'), findsOneWidget);
    });

    testWidgets('the tour advances a step at a time', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      expect(find.text('1 / 11'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Next'));
      await tester.pump();
      expect(find.text('2 / 11'), findsOneWidget);
    });

    testWidgets('a style chosen in the gallery reaches the playground', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      await tester.tap(find.widgetWithText(ChoiceChip, 'odometer'));
      await tester.pump();

      await tester.tap(find.text('Playground'));
      await tester.pumpAndSettle();

      // Stagger is meaningless for odometer, so the slider says why.
      expect(find.text('odometer wheels share one shaft'), findsOneWidget);
      final Slider stagger = tester.widget<Slider>(find.byType(Slider).last);
      expect(stagger.onChanged, isNull);
    });

    testWidgets('the stagger slider is live for a style that has one', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      await tester.tap(find.text('Playground'));
      await tester.pumpAndSettle();

      final Slider stagger = tester.widget<Slider>(find.byType(Slider).last);
      expect(stagger.onChanged, isNotNull);
      expect(stagger.value, const RollingMotion().staggerAmount);
    });
  });

  group('PortfolioScreen', () {
    testWidgets('renders the holdings, each in its own scope', (
      WidgetTester tester,
    ) async {
      await pumpDemo(tester);

      await tester.tap(find.text('Portfolio'));
      await tester.pumpAndSettle();

      expect(find.text('ARLO'), findsOneWidget);
      expect(find.text('Portfolio value'), findsOneWidget);

      await tester.tap(find.widgetWithText(OutlinedButton, 'One tick'));
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

  group('RecordScreen', () {
    test('fromRouteName resolves every style and the hero', () {
      for (final NumberMotionStyle style in NumberMotionStyle.values) {
        final RecordScreen? screen = RecordScreen.fromRouteName(
          recordRouteFor(style),
        );
        expect(screen, isNotNull, reason: 'no route for $style');
        expect(screen!.style, style);
        expect(screen.hero, isFalse);
      }
      expect(RecordScreen.fromRouteName('/record/hero')?.hero, isTrue);
    });

    test('fromRouteName declines anything else', () {
      expect(RecordScreen.fromRouteName(null), isNull);
      expect(RecordScreen.fromRouteName('/'), isNull);
      expect(RecordScreen.fromRouteName('/record/'), isNull);
      expect(RecordScreen.fromRouteName('/record/nope'), isNull);
    });

    testWidgets('renders chrome-free, so nothing lands in the crop', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: RecordScreen(style: NumberMotionStyle.flip)),
      );
      await tester.pump();

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.text('flip'), findsOneWidget);

      // Let one beat pass, then tear the screen down so its periodic timer is
      // cancelled in dispose rather than left pending at the end of the test.
      await tester.pump(const Duration(milliseconds: 2200));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
