import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/src/core/motion_direction.dart';
import 'package:motion_number/src/core/value_transition.dart';

void main() {
  group('ValueTransition.between', () {
    test('computes delta, percent and direction for an increase', () {
      final ValueTransition t = ValueTransition.between(124350, 131890);

      expect(t.from, 124350);
      expect(t.to, 131890);
      expect(t.delta, 7540);
      expect(t.direction, MotionDirection.up);
      // The worked example from the architecture doc. Note the doc rounds this
      // to +6.05%, which is wrong: 7540 / 124350 = 6.0635%, i.e. +6.06%.
      expect(t.percentChange, closeTo(6.06353, 0.00001));
    });

    test('computes a negative percent for a decrease', () {
      final ValueTransition t = ValueTransition.between(200, 150);

      expect(t.delta, -50);
      expect(t.direction, MotionDirection.down);
      expect(t.percentChange, closeTo(-25.0, 1e-9));
    });

    test('reports MotionDirection.none when the value is unchanged', () {
      final ValueTransition t = ValueTransition.between(42, 42);

      expect(t.delta, 0);
      expect(t.direction, MotionDirection.none);
      expect(t.percentChange, 0.0);
    });

    test('percentChange is null when from == 0', () {
      // The documented edge case: percent change from zero is undefined,
      // not infinite and not 100%.
      final ValueTransition t = ValueTransition.between(0, 500);

      expect(t.delta, 500);
      expect(t.direction, MotionDirection.up);
      expect(t.percentChange, isNull);
    });

    test('percentChange is null for 0.0 as well as integer 0', () {
      expect(ValueTransition.between(0.0, 1.5).percentChange, isNull);
    });

    test('percentChange is null when both values are zero', () {
      final ValueTransition t = ValueTransition.between(0, 0);

      expect(t.direction, MotionDirection.none);
      expect(t.percentChange, isNull);
    });

    test('uses the magnitude of `from` so sign comes from the delta', () {
      // -100 -> -50 is an increase of 50 on a base of 100: +50%.
      final ValueTransition t = ValueTransition.between(-100, -50);

      expect(t.direction, MotionDirection.up);
      expect(t.percentChange, closeTo(50.0, 1e-9));
    });

    test('handles a decrease that crosses zero', () {
      final ValueTransition t = ValueTransition.between(50, -50);

      expect(t.delta, -100);
      expect(t.direction, MotionDirection.down);
      expect(t.percentChange, closeTo(-200.0, 1e-9));
    });

    test('isFirstBuild defaults to false and is preserved when set', () {
      expect(ValueTransition.between(1, 2).isFirstBuild, isFalse);
      expect(
        ValueTransition.between(1, 2, isFirstBuild: true).isFirstBuild,
        isTrue,
      );
    });

    test('rejects non-finite input', () {
      expect(() => ValueTransition.between(double.nan, 1), throwsArgumentError);
      expect(
        () => ValueTransition.between(1, double.infinity),
        throwsArgumentError,
      );
    });
  });

  group('ValueTransition.initial', () {
    test('is a still transition marked as the first build', () {
      final ValueTransition t = ValueTransition.initial(99);

      expect(t.from, 99);
      expect(t.to, 99);
      expect(t.delta, 0);
      expect(t.direction, MotionDirection.none);
      expect(t.isFirstBuild, isTrue);
    });
  });

  group('MotionDirection', () {
    test('sign drives the translation direction', () {
      expect(MotionDirection.up.sign, 1);
      expect(MotionDirection.down.sign, -1);
      expect(MotionDirection.none.sign, 0);
    });

    test('exposes a spoken label rather than a glyph', () {
      expect(MotionDirection.up.semanticLabel, 'up');
      expect(MotionDirection.down.semanticLabel, 'down');
      expect(MotionDirection.none.semanticLabel, 'unchanged');
    });
  });

  group('value semantics', () {
    test('equal transitions compare equal and hash alike', () {
      final ValueTransition a = ValueTransition.between(1, 2);
      final ValueTransition b = ValueTransition.between(1, 2);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing transitions are not equal', () {
      expect(
        ValueTransition.between(1, 2),
        isNot(equals(ValueTransition.between(1, 3))),
      );
    });
  });
}
