import 'package:flutter/widgets.dart';

import '../core/motion_direction.dart';

/// The colours used to tint a number and its delta by direction.
///
/// Financial UIs encode direction in colour as much as in motion. Keeping the
/// pair in one object means an app can express its convention once — and
/// red-for-up is the convention in several markets, so this is not hard-coded.
@immutable
class DirectionColors {
  /// Creates a colour pair.
  const DirectionColors({required this.up, required this.down, this.none});

  /// Green for up, red for down: the common Western convention.
  const DirectionColors.greenUp()
    : up = const Color(0xFF15803D),
      down = const Color(0xFFB91C1C),
      none = null;

  /// Red for up, green for down, as used in parts of East and South Asia.
  const DirectionColors.redUp()
    : up = const Color(0xFFB91C1C),
      down = const Color(0xFF15803D),
      none = null;

  /// The colour for a rising value.
  final Color up;

  /// The colour for a falling value.
  final Color down;

  /// The colour for an unchanged value, or `null` to inherit the text colour.
  final Color? none;

  /// The colour for [direction], or `null` to leave the text colour alone.
  Color? resolve(MotionDirection direction) => switch (direction) {
    MotionDirection.up => up,
    MotionDirection.down => down,
    MotionDirection.none => none,
  };

  /// Linearly interpolates between two colour pairs.
  static DirectionColors? lerp(
    DirectionColors? a,
    DirectionColors? b,
    double t,
  ) {
    if (a == null && b == null) {
      return null;
    }
    return DirectionColors(
      up: Color.lerp(a?.up, b?.up, t) ?? (b ?? a)!.up,
      down: Color.lerp(a?.down, b?.down, t) ?? (b ?? a)!.down,
      none: Color.lerp(a?.none, b?.none, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DirectionColors &&
          other.up == up &&
          other.down == down &&
          other.none == none;

  @override
  int get hashCode => Object.hash(up, down, none);
}
