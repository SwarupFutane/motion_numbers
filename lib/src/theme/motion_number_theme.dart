import 'package:flutter/material.dart';

import '../motion/number_motion_style.dart';
import 'direction_colors.dart';

/// Application-wide defaults for `MotionNumber` and `MotionDelta`.
///
/// Register it once on [ThemeData] and every call site inherits the same motion
/// language, instead of repeating the same four arguments at forty of them:
///
/// ```dart
/// ThemeData(
///   extensions: <ThemeExtension<dynamic>>[
///     MotionNumberTheme(
///       style: NumberMotionStyle.odometer,
///       directionColors: DirectionColors.greenUp(),
///     ),
///   ],
/// )
/// ```
///
/// Every field is nullable: an unset field falls through to the motion style's
/// own default, and an explicit argument on the widget always wins.
@immutable
class MotionNumberTheme extends ThemeExtension<MotionNumberTheme> {
  /// Creates a set of defaults.
  const MotionNumberTheme({
    this.style,
    this.duration,
    this.curve,
    this.directionColors,
    this.deltaTextStyle,
  });

  /// The default motion style.
  final NumberMotionStyle? style;

  /// The default transition duration.
  final Duration? duration;

  /// The default easing curve.
  final Curve? curve;

  /// The default direction colours.
  final DirectionColors? directionColors;

  /// The default text style for `MotionDelta`.
  final TextStyle? deltaTextStyle;

  /// The nearest theme extension, or `null` if none is registered.
  static MotionNumberTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<MotionNumberTheme>();

  @override
  MotionNumberTheme copyWith({
    NumberMotionStyle? style,
    Duration? duration,
    Curve? curve,
    DirectionColors? directionColors,
    TextStyle? deltaTextStyle,
  }) => MotionNumberTheme(
    style: style ?? this.style,
    duration: duration ?? this.duration,
    curve: curve ?? this.curve,
    directionColors: directionColors ?? this.directionColors,
    deltaTextStyle: deltaTextStyle ?? this.deltaTextStyle,
  );

  @override
  MotionNumberTheme lerp(ThemeExtension<MotionNumberTheme>? other, double t) {
    if (other is! MotionNumberTheme) {
      return this;
    }
    return MotionNumberTheme(
      // Style and curve are discrete: snapping at the midpoint beats
      // interpolating towards something that is not a valid value.
      style: t < 0.5 ? style : other.style,
      duration: t < 0.5 ? duration : other.duration,
      curve: t < 0.5 ? curve : other.curve,
      directionColors: DirectionColors.lerp(
        directionColors,
        other.directionColors,
        t,
      ),
      deltaTextStyle: TextStyle.lerp(deltaTextStyle, other.deltaTextStyle, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MotionNumberTheme &&
          other.style == style &&
          other.duration == duration &&
          other.curve == curve &&
          other.directionColors == directionColors &&
          other.deltaTextStyle == deltaTextStyle;

  @override
  int get hashCode =>
      Object.hash(style, duration, curve, directionColors, deltaTextStyle);
}
