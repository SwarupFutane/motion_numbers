import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/motion_number.dart';

/// Every code sample and claimed output in README.md, compiled and run.
///
/// The README is the marketing surface and the parameter tables are the only
/// reference until 1.0.0. Pinning its claims here is what stops it drifting
/// away from the API it documents.
void main() {
  testWidgets('readme samples build', (WidgetTester tester) async {
    const int amount = 131890;

    final Widget app = MaterialApp(
      theme: ThemeData(
        extensions: const <ThemeExtension<dynamic>>[
          MotionNumberTheme(
            style: NumberMotionStyle.odometer,
            duration: Duration(milliseconds: 700),
            directionColors: DirectionColors.greenUp(),
          ),
        ],
      ),
      home: Scaffold(
        body: Column(
          children: <Widget>[
            const MotionNumber(value: 131890),
            const MotionNumber(value: 131890, style: NumberMotionStyle.flip),
            Row(
              children: <Widget>[
                MotionNumber(
                  value: amount,
                  formatter: IntlFormatter.currency(
                    locale: 'en_IN',
                    symbol: '₹',
                    decimalDigits: 0,
                  ),
                  directionColors: const DirectionColors.greenUp(),
                ),
                const SizedBox(width: 8),
                const MotionDelta(),
              ],
            ),
          ],
        ),
      ),
    );

    await tester.pumpWidget(app);
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
  });

  test('readme formatter table', () {
    expect(const PlainFormatter().format(131890), '131,890');
    expect(const PlainFormatter(grouped: false).format(131890), '131890');
    expect(IntlFormatter.decimal(locale: 'en_IN').format(124350), '1,24,350');
    expect(
      IntlFormatter.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      ).format(124350),
      '₹1,24,350',
    );
    expect(const CompactFormatter().format(1243500), '1.2M');
    expect(
      const CompactFormatter(scale: CompactScale.indian).format(1243500),
      '12.4L',
    );
  });

  test('readme delta claim', () {
    final ValueTransition t = ValueTransition.between(124350, 131890);
    expect(MotionDelta.arrowFor(t.direction), '↑');
    expect(MotionDelta.label(t), '+6.06%');
  });
}
