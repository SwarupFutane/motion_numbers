import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/src/core/digit_metrics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(DigitMetrics.clearCache);

  const TextStyle style = TextStyle(fontSize: 20);

  group('DigitMetrics.measure', () {
    test('returns the widest advance width across the digits 0-9', () {
      double widest = 0;
      for (int digit = 0; digit <= 9; digit++) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: '$digit', style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        widest = painter.width > widest ? painter.width : widest;
        painter.dispose();
      }

      expect(DigitMetrics.measure(style).width, widest);
    });

    test('reports a positive width and height', () {
      final Size size = DigitMetrics.measure(style);

      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('scales with fontSize', () {
      final Size small = DigitMetrics.measure(const TextStyle(fontSize: 10));
      final Size large = DigitMetrics.measure(const TextStyle(fontSize: 40));

      expect(large.width, greaterThan(small.width));
      expect(large.height, greaterThan(small.height));
    });

    test('honours a TextScaler', () {
      final Size plain = DigitMetrics.measure(style);
      final Size scaled = DigitMetrics.measure(
        style,
        textScaler: const TextScaler.linear(2),
      );

      expect(scaled.height, greaterThan(plain.height));
    });
  });

  group('caching', () {
    test('measures once per style and reuses the result', () {
      expect(DigitMetrics.cacheSize, 0);

      final Size first = DigitMetrics.measure(style);
      expect(DigitMetrics.cacheSize, 1);

      final Size second = DigitMetrics.measure(style);
      expect(DigitMetrics.cacheSize, 1, reason: 'equal styles share an entry');
      expect(second, first);
    });

    test('keys on style equality, not identity', () {
      // Built at runtime so the two styles cannot be canonicalised into the
      // same const instance — the cache must match them by value.
      final double size = double.parse('20');

      DigitMetrics.measure(const TextStyle(fontSize: 20));
      DigitMetrics.measure(TextStyle(fontSize: size));

      expect(DigitMetrics.cacheSize, 1);
    });

    test('caches distinct styles separately', () {
      DigitMetrics.measure(const TextStyle(fontSize: 20));
      DigitMetrics.measure(const TextStyle(fontSize: 21));

      expect(DigitMetrics.cacheSize, 2);
    });

    test('caches distinct scalers separately', () {
      DigitMetrics.measure(style);
      DigitMetrics.measure(style, textScaler: const TextScaler.linear(2));

      expect(DigitMetrics.cacheSize, 2);
    });

    test('clearCache empties the cache', () {
      DigitMetrics.measure(style);
      DigitMetrics.clearCache();

      expect(DigitMetrics.cacheSize, 0);
    });
  });

  group('withTabularFigures', () {
    test('adds the tnum feature', () {
      final TextStyle result = DigitMetrics.withTabularFigures(style);

      expect(result.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('preserves existing font features', () {
      const TextStyle withSlashedZero = TextStyle(
        fontFeatures: <FontFeature>[FontFeature.slashedZero()],
      );

      final TextStyle result = DigitMetrics.withTabularFigures(withSlashedZero);

      expect(result.fontFeatures, hasLength(2));
      expect(result.fontFeatures, contains(const FontFeature.slashedZero()));
      expect(result.fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('is a no-op when tabular figures are already requested', () {
      const TextStyle already = TextStyle(
        fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
      );

      expect(DigitMetrics.withTabularFigures(already), same(already));
    });
  });
}
