import 'package:flutter/widgets.dart';

import '../core/motion_direction.dart';
import '../core/value_transition.dart';
import '../theme/direction_colors.dart';
import '../theme/motion_number_theme.dart';
import 'motion_number_scope.dart';

/// Renders the change that accompanied a number: `↑ +6.06%`.
///
/// A sibling widget rather than a parameter, so it can sit anywhere in the
/// layout. It reads the nearest [MotionNumberScope], or takes an explicit
/// [transition]:
///
/// ```dart
/// MotionNumberScope(
///   child: Column(
///     children: <Widget>[
///       MotionNumber(value: portfolio),
///       MotionDelta(),
///     ],
///   ),
/// )
/// ```
///
/// The arrow is decorative: screen readers are given the direction as a word,
/// because `↑` is not reliably spoken.
class MotionDelta extends StatelessWidget {
  /// Creates a delta indicator.
  const MotionDelta({
    this.transition,
    this.decimalDigits = 2,
    this.showArrow = true,
    this.textStyle,
    this.directionColors,
    this.deltaBuilder,
    super.key,
  }) : assert(decimalDigits >= 0, 'decimalDigits must not be negative');

  /// The transition to render. Defaults to the nearest scope's.
  final ValueTransition? transition;

  /// Digits shown after the decimal point in the percentage.
  final int decimalDigits;

  /// Whether to prefix the text with a direction arrow.
  final bool showArrow;

  /// The text style. Defaults to the theme's `deltaTextStyle`, then ambient.
  final TextStyle? textStyle;

  /// Colours applied by direction. Defaults to the theme's.
  final DirectionColors? directionColors;

  /// Builds custom content instead of the default arrow-and-percentage text.
  final Widget Function(BuildContext, ValueTransition)? deltaBuilder;

  /// The arrow for [direction], or an empty string when it is unchanged.
  static String arrowFor(MotionDirection direction) => switch (direction) {
    MotionDirection.up => '↑',
    MotionDirection.down => '↓',
    MotionDirection.none => '',
  };

  /// Formats [transition] as a signed percentage, or as a signed delta when the
  /// percentage is undefined.
  ///
  /// Percentage change from zero is undefined, so a transition starting at zero
  /// shows the absolute change instead of `∞%` or a silently wrong `100%`.
  static String label(ValueTransition transition, {int decimalDigits = 2}) {
    final double? percent = transition.percentChange;
    if (percent == null) {
      final num delta = transition.delta;
      return '${delta > 0 ? '+' : ''}$delta';
    }
    final String magnitude = percent.abs().toStringAsFixed(decimalDigits);
    final String sign = switch (transition.direction) {
      MotionDirection.up => '+',
      MotionDirection.down => '-',
      MotionDirection.none => '',
    };
    return '$sign$magnitude%';
  }

  /// A spoken description, using words rather than glyphs.
  static String semanticLabelFor(
    ValueTransition transition, {
    int decimalDigits = 2,
  }) {
    final double? percent = transition.percentChange;
    if (percent == null) {
      return '${transition.direction.semanticLabel} '
          '${transition.delta.abs()}';
    }
    if (transition.direction.isNone) {
      return 'unchanged';
    }
    return '${transition.direction.semanticLabel} '
        '${percent.abs().toStringAsFixed(decimalDigits)} percent';
  }

  @override
  Widget build(BuildContext context) {
    final ValueTransition? resolved =
        transition ?? MotionNumberScope.maybeOf(context);
    if (resolved == null) {
      return const SizedBox.shrink();
    }

    final MotionNumberTheme? theme = MotionNumberTheme.maybeOf(context);
    if (deltaBuilder != null) {
      return deltaBuilder!(context, resolved);
    }

    final DirectionColors? colors = directionColors ?? theme?.directionColors;
    final TextStyle base =
        textStyle ??
        theme?.deltaTextStyle ??
        DefaultTextStyle.of(context).style;
    final Color? tint = colors?.resolve(resolved.direction);
    final TextStyle style = tint == null ? base : base.copyWith(color: tint);

    final String arrow = showArrow ? arrowFor(resolved.direction) : '';
    final String text = label(resolved, decimalDigits: decimalDigits);

    return Semantics(
      label: semanticLabelFor(resolved, decimalDigits: decimalDigits),
      liveRegion: true,
      child: ExcludeSemantics(
        child: Text(arrow.isEmpty ? text : '$arrow $text', style: style),
      ),
    );
  }
}
