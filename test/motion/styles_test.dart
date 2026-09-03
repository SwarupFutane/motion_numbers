import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/src/core/glyph_differ.dart';
import 'package:motion_number/src/core/motion_direction.dart';
import 'package:motion_number/src/motion/digit_motion.dart';
import 'package:motion_number/src/motion/number_motion_style.dart';
import 'package:motion_number/src/motion/slot_render_data.dart';
import 'package:motion_number/src/motion/styles/flip_motion.dart';
import 'package:motion_number/src/motion/styles/odometer_motion.dart';
import 'package:motion_number/src/motion/styles/rolling_motion.dart';
import 'package:motion_number/src/motion/styles/shuffle_motion.dart';
import 'package:motion_number/src/motion/styles/slot_machine_motion.dart';
import 'package:motion_number/src/widgets/motion_number.dart';

SlotRenderData dataFor(
  int from,
  int to, {
  int slotIndex = 0,
  int slotCount = 3,
  MotionDirection direction = MotionDirection.up,
}) => SlotRenderData(
  instruction: RollSlot(from: from, to: to, placeIndex: 0),
  slotIndex: slotIndex,
  slotCount: slotCount,
  direction: direction,
  cellSize: const Size(10, 20),
  textStyle: const TextStyle(fontSize: 20),
  strip: const SizedBox.shrink(),
  stripRepeats: 2,
);

void main() {
  final List<DigitMotion> styles = NumberMotionStyle.values
      .map(resolveMotionStyle)
      .toList();

  group('every style satisfies the contract', () {
    test('resolves a distinct implementation per enum value', () {
      expect(
        styles.map((DigitMotion m) => m.runtimeType).toSet(),
        hasLength(NumberMotionStyle.values.length),
        reason: 'no two styles may share an implementation',
      );
    });

    test('declares a positive duration and at least one strip repeat', () {
      for (final DigitMotion motion in styles) {
        expect(motion.defaultDuration, greaterThan(Duration.zero));
        expect(motion.stripRepeats, greaterThanOrEqualTo(1));
      }
    });

    test('localT starts at 0 and ends at 1 for every slot', () {
      for (final DigitMotion motion in styles) {
        for (int i = 0; i < 5; i++) {
          expect(motion.localT(0, i, 5, MotionDirection.up), 0);
          expect(
            motion.localT(1, i, 5, MotionDirection.up),
            greaterThanOrEqualTo(1),
            reason: '${motion.runtimeType} slot $i',
          );
        }
      }
    });

    test('localT is monotonic in the global time', () {
      for (final DigitMotion motion in styles) {
        for (int i = 0; i < 5; i++) {
          double previous = -1;
          for (double t = 0; t <= 1.0001; t += 0.05) {
            final double local = motion.localT(t, i, 5, MotionDirection.up);
            expect(
              local,
              greaterThanOrEqualTo(previous),
              reason: '${motion.runtimeType} slot $i at $t',
            );
            previous = local;
          }
        }
      }
    });

    test('visibleDigit is always a digit', () {
      for (final DigitMotion motion in styles) {
        for (double t = 0; t <= 1.0001; t += 0.1) {
          expect(
            motion.visibleDigit(dataFor(7, 2), t),
            inInclusiveRange(0, 9),
            reason: '${motion.runtimeType} at $t',
          );
        }
      }
    });

    test('visibleDigit lands on the target at t = 1', () {
      for (final DigitMotion motion in styles) {
        expect(
          motion.visibleDigit(dataFor(7, 2), 1),
          2,
          reason: '${motion.runtimeType}',
        );
      }
    });

    test('every path stays inside the strip the style asked for', () {
      // The invariant that makes stripRepeats sufficient rather than hopeful.
      for (final NumberMotionStyle style in NumberMotionStyle.values) {
        final DigitMotion motion = resolveMotionStyle(style);
        for (int from = 0; from <= 9; from++) {
          for (int to = 0; to <= 9; to++) {
            for (final MotionDirection d in MotionDirection.values) {
              for (int slot = 0; slot < 6; slot++) {
                for (final double t in const <double>[0, 0.3, 0.6, 0.9, 1]) {
                  final int digit = motion.visibleDigit(
                    dataFor(from, to, slotIndex: slot, direction: d),
                    t,
                  );
                  expect(digit, inInclusiveRange(0, 9), reason: '$style');
                }
              }
            }
          }
        }
      }
    });
  });

  group('style-specific behaviour', () {
    test('rolling takes the shortcut from 1 to 9', () {
      expect(
        DigitMotion.shortestDistance(1, 9, MotionDirection.up),
        -2,
        reason: 'rolling drops two rather than climbing eight',
      );
    });

    test('odometer refuses the shortcut', () {
      expect(
        DigitMotion.continuousDistance(1, 9, MotionDirection.up),
        8,
        reason: 'a dial carries the whole way',
      );
    });

    test('odometer and rolling therefore disagree mid-transition', () {
      final int rolling = const RollingMotion().visibleDigit(
        dataFor(1, 9),
        0.5,
      );
      final int odometer = const OdometerMotion().visibleDigit(
        dataFor(1, 9),
        0.5,
      );

      expect(rolling, isNot(odometer));
    });

    test('slotMachine needs a longer strip than the others', () {
      expect(const SlotMachineMotion().stripRepeats, greaterThan(2));
    });

    test('slotMachine spins different slots by different amounts', () {
      const SlotMachineMotion motion = SlotMachineMotion();
      final Set<int> digits = <int>{};
      for (int slot = 0; slot < 3; slot++) {
        digits.add(motion.visibleDigit(dataFor(0, 0, slotIndex: slot), 0.5));
      }

      expect(digits.length, greaterThan(1), reason: 'slots must desynchronise');
    });

    test('flip shows the old digit first and the new digit second', () {
      const FlipMotion motion = FlipMotion();

      expect(motion.visibleDigit(dataFor(3, 8), 0.2), 3);
      expect(motion.visibleDigit(dataFor(3, 8), 0.8), 8);
    });

    test('flip does not need the digit strip', () {
      expect(const FlipMotion().stripRepeats, 1);
    });

    test('shuffle is deterministic across calls', () {
      const ShuffleMotion motion = ShuffleMotion();

      for (double t = 0; t <= 1.0001; t += 0.1) {
        expect(
          motion.visibleDigit(dataFor(1, 7, slotIndex: 2), t),
          motion.visibleDigit(dataFor(1, 7, slotIndex: 2), t),
          reason: 'a re-render at the same t must look identical',
        );
      }
    });

    test('shuffle scrambles before it settles', () {
      const ShuffleMotion motion = ShuffleMotion();
      final Set<int> seen = <int>{};
      for (double t = 0; t < 0.6; t += 0.05) {
        seen.add(motion.visibleDigit(dataFor(1, 7, slotIndex: 2), t));
      }

      expect(seen.length, greaterThan(2), reason: 'it should look scrambled');
    });
  });

  group('every style animates end to end', () {
    Widget host(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 20),
        child: Center(child: child),
      ),
    );

    for (final NumberMotionStyle style in NumberMotionStyle.values) {
      testWidgets('$style renders and settles', (WidgetTester tester) async {
        await tester.pumpWidget(host(MotionNumber(value: 1234, style: style)));
        await tester.pumpWidget(host(MotionNumber(value: 5678, style: style)));

        for (final int ms in const <int>[1, 100, 300, 600]) {
          await tester.pump(Duration(milliseconds: ms));
          expect(tester.takeException(), isNull, reason: '$style at $ms ms');
        }

        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  });
}
