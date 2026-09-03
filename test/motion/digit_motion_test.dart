import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/src/core/motion_direction.dart';
import 'package:motion_number/src/motion/digit_motion.dart';

void main() {
  group('DigitMotion.shortestDistance', () {
    test('takes the short way up', () {
      expect(DigitMotion.shortestDistance(1, 3, MotionDirection.up), 2);
    });

    test('takes the short way down', () {
      expect(DigitMotion.shortestDistance(3, 1, MotionDirection.down), -2);
    });

    test('wraps 9 -> 0 as a single step up', () {
      expect(DigitMotion.shortestDistance(9, 0, MotionDirection.up), 1);
    });

    test('wraps 0 -> 9 as a single step down', () {
      expect(DigitMotion.shortestDistance(0, 9, MotionDirection.down), -1);
    });

    test('prefers the shorter path even against the value direction', () {
      // 1 -> 9 is 8 steps up but only 2 down; shortest wins.
      expect(DigitMotion.shortestDistance(1, 9, MotionDirection.up), -2);
    });

    test('breaks a five-step tie using the direction', () {
      expect(DigitMotion.shortestDistance(0, 5, MotionDirection.up), 5);
      expect(DigitMotion.shortestDistance(0, 5, MotionDirection.down), -5);
    });

    test('is zero when the digit does not change', () {
      for (final MotionDirection d in MotionDirection.values) {
        expect(DigitMotion.shortestDistance(4, 4, d), 0);
      }
    });

    test('never exceeds five steps in either direction', () {
      for (int from = 0; from <= 9; from++) {
        for (int to = 0; to <= 9; to++) {
          for (final MotionDirection d in MotionDirection.values) {
            expect(
              DigitMotion.shortestDistance(from, to, d).abs(),
              lessThanOrEqualTo(5),
              reason: '$from -> $to ($d)',
            );
          }
        }
      }
    });
  });

  group('DigitMotion.continuousDistance', () {
    test('always travels with the value, however far', () {
      // 1 -> 9 upward is the long way round, and that is the point.
      expect(DigitMotion.continuousDistance(1, 9, MotionDirection.up), 8);
      expect(DigitMotion.continuousDistance(9, 1, MotionDirection.down), -8);
    });

    test('carries through the 9 -> 0 boundary', () {
      expect(DigitMotion.continuousDistance(9, 0, MotionDirection.up), 1);
      expect(DigitMotion.continuousDistance(0, 9, MotionDirection.down), -1);
    });

    test('falls back to the shortest path when nothing moved', () {
      expect(DigitMotion.continuousDistance(2, 7, MotionDirection.none), 5);
    });
  });

  group('DigitMotion.stripPosition', () {
    test('starts at the origin digit and ends at the target', () {
      final double distance = DigitMotion.shortestDistance(
        2,
        5,
        MotionDirection.up,
      );

      expect(DigitMotion.stripPosition(2, distance, 0), 2);
      expect(DigitMotion.stripPosition(2, distance, 1), 5);
    });

    test('offsets downward paths by a revolution to stay positive', () {
      final double distance = DigitMotion.shortestDistance(
        1,
        8,
        MotionDirection.down,
      );

      expect(distance, -3);
      expect(DigitMotion.stripPosition(1, distance, 0), 11);
      expect(DigitMotion.stripPosition(1, distance, 1), 8);
    });

    test('stays inside a two-repeat strip for every shortest path', () {
      // The invariant that lets the strip be 20 cells rather than 30.
      for (int from = 0; from <= 9; from++) {
        for (int to = 0; to <= 9; to++) {
          for (final MotionDirection d in MotionDirection.values) {
            final double distance = DigitMotion.shortestDistance(from, to, d);
            for (final double t in const <double>[0, 0.25, 0.5, 0.75, 1]) {
              final double p = DigitMotion.stripPosition(from, distance, t);
              expect(p, inInclusiveRange(0, 20), reason: '$from->$to $d t=$t');
            }
          }
        }
      }
    });

    test('is monotonic along the path', () {
      final double distance = DigitMotion.shortestDistance(
        8,
        2,
        MotionDirection.up,
      );
      double previous = DigitMotion.stripPosition(8, distance, 0);

      for (double t = 0.1; t <= 1.0; t += 0.1) {
        final double current = DigitMotion.stripPosition(8, distance, t);
        expect(current, greaterThanOrEqualTo(previous));
        previous = current;
      }
    });
  });

  group('DigitMotion.stagger', () {
    test('is the identity when amount is zero', () {
      expect(DigitMotion.stagger(0.4, 2, 5, amount: 0), 0.4);
    });

    test('is the identity for a single slot', () {
      expect(DigitMotion.stagger(0.4, 0, 1, amount: 0.5), 0.4);
    });

    test('delays later slots', () {
      const double globalT = 0.5;
      final double first = DigitMotion.stagger(globalT, 0, 4, amount: 0.4);
      final double last = DigitMotion.stagger(globalT, 3, 4, amount: 0.4);

      expect(first, greaterThan(last));
    });

    test('reverse delays earlier slots instead', () {
      const double globalT = 0.5;
      final double first = DigitMotion.stagger(
        globalT,
        0,
        4,
        amount: 0.4,
        reverse: true,
      );
      final double last = DigitMotion.stagger(
        globalT,
        3,
        4,
        amount: 0.4,
        reverse: true,
      );

      expect(last, greaterThan(first));
    });

    test('every slot starts at 0 and finishes at 1', () {
      for (int i = 0; i < 6; i++) {
        expect(DigitMotion.stagger(0, i, 6, amount: 0.6), 0);
        expect(DigitMotion.stagger(1, i, 6, amount: 0.6), 1);
      }
    });

    test('stays in range and is monotonic for every slot', () {
      for (int i = 0; i < 6; i++) {
        double previous = 0;
        for (double t = 0; t <= 1.0001; t += 0.05) {
          final double local = DigitMotion.stagger(t, i, 6, amount: 0.5);
          expect(local, inInclusiveRange(0, 1));
          expect(local, greaterThanOrEqualTo(previous));
          previous = local;
        }
      }
    });
  });
}
