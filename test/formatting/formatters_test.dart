import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:motion_number/src/formatting/compact_formatter.dart';
import 'package:motion_number/src/formatting/intl_formatter.dart';
import 'package:motion_number/src/formatting/plain_formatter.dart';

void main() {
  group('PlainFormatter', () {
    test('groups thousands from the right', () {
      const PlainFormatter f = PlainFormatter();

      expect(f.format(1), '1');
      expect(f.format(999), '999');
      expect(f.format(1000), '1,000');
      expect(f.format(124350), '124,350');
      expect(f.format(1234567), '1,234,567');
    });

    test('groups Western-style even for Indian-sized numbers', () {
      // The documented limitation: fixed three-digit groups. Locale-correct
      // grouping is IntlFormatter's job.
      expect(const PlainFormatter().format(124350), '124,350');
    });

    test('can disable grouping entirely', () {
      expect(const PlainFormatter(grouped: false).format(1234567), '1234567');
    });

    test('renders a negative sign before the digits', () {
      expect(const PlainFormatter().format(-1234), '-1,234');
    });

    test('does not sign negative zero', () {
      expect(const PlainFormatter().format(-0.0), '0');
    });

    test('rounds to decimalDigits', () {
      const PlainFormatter f = PlainFormatter(decimalDigits: 2);

      expect(f.format(1234.5678), '1,234.57');
      expect(f.format(1000), '1,000.00');
    });

    test('honours prefix, suffix and custom separators', () {
      const PlainFormatter f = PlainFormatter(
        decimalDigits: 2,
        groupSeparator: ' ',
        decimalSeparator: ',',
        prefix: '€',
        suffix: ' EUR',
      );

      expect(f.format(1234.5), '€1 234,50 EUR');
    });

    test('handles zero and values below the grouping threshold', () {
      expect(const PlainFormatter().format(0), '0');
      expect(const PlainFormatter().format(42), '42');
    });
  });

  group('IntlFormatter', () {
    test('en_IN yields 1,24,350 rather than 124,350', () {
      // The done-criterion for this layer: Indian grouping pairs the leading
      // digits, which no fixed-width grouper can reproduce.
      expect(IntlFormatter.decimal(locale: 'en_IN').format(124350), '1,24,350');
    });

    test('en_US groups in threes', () {
      expect(IntlFormatter.decimal(locale: 'en_US').format(124350), '124,350');
    });

    test('formats Indian currency with a rupee symbol', () {
      final IntlFormatter f = IntlFormatter.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      );

      expect(f.format(124350), '₹1,24,350');
      expect(f.format(131890), '₹1,31,890');
    });

    test('wraps an arbitrary NumberFormat', () {
      final IntlFormatter f = IntlFormatter(NumberFormat('#,##0.00', 'en_US'));

      expect(f.format(1234.5), '1,234.50');
    });

    test('exposes the underlying format', () {
      final IntlFormatter f = IntlFormatter.decimal(locale: 'en_US');

      expect(f.numberFormat, isA<NumberFormat>());
    });
  });

  group('CompactFormatter — western', () {
    const CompactFormatter f = CompactFormatter();

    test('produces the documented examples', () {
      expect(f.format(1200), '1.2K');
      expect(f.format(1200000), '1.2M');
    });

    test('covers each magnitude', () {
      expect(f.format(999), '999');
      expect(f.format(1000), '1K');
      expect(f.format(1500000000), '1.5B');
      expect(f.format(2000000000000), '2T');
    });

    test('trims a trailing zero fraction by default', () {
      expect(f.format(1000), '1K');
      expect(
        const CompactFormatter(trimTrailingZeros: false).format(1000),
        '1.0K',
      );
    });

    test('signs negatives', () {
      expect(f.format(-1200), '-1.2K');
    });

    test('leaves small values exact', () {
      expect(f.format(0), '0');
      expect(f.format(42), '42');
    });
  });

  group('CompactFormatter — indian', () {
    const CompactFormatter f = CompactFormatter(scale: CompactScale.indian);

    test('produces the documented 12.4L example', () {
      expect(f.format(1240000), '12.4L');
    });

    test('uses lakh and crore instead of million', () {
      expect(f.format(100000), '1L');
      expect(f.format(10000000), '1Cr');
      expect(f.format(25000000), '2.5Cr');
    });

    test('differs from the western scale at the same value', () {
      expect(const CompactFormatter().format(1240000), '1.2M');
      expect(f.format(1240000), '12.4L');
    });
  });

  group('CompactFormatter — options', () {
    test('honours fractionDigits', () {
      expect(const CompactFormatter(fractionDigits: 2).format(1234), '1.23K');
    });

    test('honours prefix and suffix', () {
      expect(const CompactFormatter(prefix: '₹').format(1200), '₹1.2K');
    });

    test('honours a custom decimal separator', () {
      expect(
        const CompactFormatter(decimalSeparator: ',').format(1200),
        '1,2K',
      );
    });
  });
}
