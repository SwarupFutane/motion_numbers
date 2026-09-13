import 'package:example/screens/record_screen.dart';
import 'package:example/tuning.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/motion_number.dart';

void main() {
  group('MotionTuning.motion', () {
    test('passes the stagger through to every style that takes one', () {
      for (final NumberMotionStyle style in NumberMotionStyle.values) {
        final MotionTuning tuning = MotionTuning(
          style: style,
          duration: const Duration(milliseconds: 700),
          stagger: 0.5,
        );
        final DigitMotion motion = tuning.motion;

        final double? applied = switch (motion) {
          RollingMotion(:final double staggerAmount) => staggerAmount,
          SlotMachineMotion(:final double staggerAmount) => staggerAmount,
          FlipMotion(:final double staggerAmount) => staggerAmount,
          WaveMotion(:final double staggerAmount) => staggerAmount,
          ShuffleMotion(:final double staggerAmount) => staggerAmount,
          ElasticMotion(:final double staggerAmount) => staggerAmount,
          _ => null,
        };

        if (tuning.staggerApplies) {
          expect(applied, 0.5, reason: 'stagger lost for $style');
        } else {
          expect(motion, isA<OdometerMotion>());
          expect(applied, isNull);
        }
      }
    });

    test('odometer is the one style with no stagger', () {
      final Iterable<NumberMotionStyle> without = NumberMotionStyle.values
          .where(
            (NumberMotionStyle s) =>
                !MotionTuning.defaultsFor(s).staggerApplies,
          );
      expect(without, <NumberMotionStyle>[NumberMotionStyle.odometer]);
    });

    test('maxStagger stays inside the assert every style declares', () {
      expect(MotionTuning.maxStagger, lessThan(1));

      // Deliberately not a const expression: the point is that the runtime
      // assert accepts the slider's top of range, not that the compiler does.
      final double top = MotionTuning.maxStagger;
      expect(() => RollingMotion(staggerAmount: top), returnsNormally);
      expect(() => SlotMachineMotion(staggerAmount: top), returnsNormally);
      expect(() => FlipMotion(staggerAmount: top), returnsNormally);
      expect(() => WaveMotion(staggerAmount: top), returnsNormally);
      expect(() => ShuffleMotion(staggerAmount: top), returnsNormally);
      expect(() => ElasticMotion(staggerAmount: top), returnsNormally);
    });
  });

  group('MotionTuning.defaultsFor', () {
    test('takes duration and stagger from the package, not from the demo', () {
      final MotionTuning tuning = MotionTuning.defaultsFor(
        NumberMotionStyle.shuffle,
      );
      expect(tuning.duration, const ShuffleMotion().defaultDuration);
      expect(tuning.stagger, const ShuffleMotion().staggerAmount);
    });
  });

  group('MotionTuning.snippet', () {
    test('names the class the tuning actually builds', () {
      for (final NumberMotionStyle style in NumberMotionStyle.values) {
        final MotionTuning tuning = MotionTuning.defaultsFor(style);
        final String type = tuning.motion.runtimeType.toString();
        expect(
          tuning.snippet,
          contains(type),
          reason: 'snippet for $style does not mention $type',
        );
      }
    });

    test('omits staggerAmount for the style that has none', () {
      final String code = MotionTuning.defaultsFor(
        NumberMotionStyle.odometer,
      ).snippet;
      expect(code, contains('const OdometerMotion()'));
      expect(code, isNot(contains('staggerAmount')));
    });

    test('carries the duration in milliseconds', () {
      final MotionTuning tuning = MotionTuning.defaultsFor(
        NumberMotionStyle.rolling,
      ).copyWith(duration: const Duration(milliseconds: 1234));
      expect(tuning.snippet, contains('Duration(milliseconds: 1234)'));
    });
  });

  group('recordRouteFor', () {
    test('round-trips through RecordScreen.fromRouteName', () {
      for (final NumberMotionStyle style in NumberMotionStyle.values) {
        expect(recordRouteFor(style), '/record/${styleLabel(style)}');
        expect(RecordScreen.fromRouteName(recordRouteFor(style))?.style, style);
      }
    });
  });
}
