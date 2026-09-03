import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/motion_direction.dart';
import '../digit_motion.dart';
import '../slot_render_data.dart';

/// An airport split-flap board.
///
/// This is the style that proves the strategy boundary is real: it cannot use
/// the translated digit strip at all. A flap is two half-height clips with an
/// X-axis rotation and a perspective matrix, and the transition happens in two
/// phases — the old top half folds down, then the new bottom half falls into
/// place. Nothing above [DigitMotion] knows the difference.
class FlipMotion extends DigitMotion {
  /// Creates a flip motion.
  const FlipMotion({this.staggerAmount = 0.4})
    : assert(
        staggerAmount >= 0 && staggerAmount < 1,
        'staggerAmount must be in [0, 1)',
      );

  /// The fraction of the timeline spread across the slots.
  final double staggerAmount;

  /// The strip is unused by this style, so one copy is plenty.
  @override
  int get stripRepeats => 1;

  @override
  Duration get defaultDuration => const Duration(milliseconds: 700);

  @override
  Curve get defaultCurve => Curves.easeInOut;

  @override
  double localT(
    double globalT,
    int slotIndex,
    int slotCount,
    MotionDirection direction,
  ) =>
      DigitMotion.stagger(globalT, slotIndex, slotCount, amount: staggerAmount);

  @override
  int visibleDigit(SlotRenderData data, double t) =>
      t < 0.5 ? data.fromDigit! : data.toDigit!;

  @override
  Widget buildSlot(BuildContext context, SlotRenderData data, double t) {
    final int from = data.fromDigit!;
    final int to = data.toDigit!;

    // A falling value folds the other way, so a decrease reads as a decrease.
    final double axis = data.direction.isDown ? -1 : 1;

    return SizedBox(
      width: data.cellWidth,
      height: data.cellHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Behind everything: the new top and the old bottom.
          _half(data, to, top: true),
          _half(data, from, top: false),
          if (t < 0.5)
            // Phase one: the old top folds away, uncovering the new top.
            _rotated(
              child: _half(data, from, top: true),
              angle: -axis * math.pi / 2 * (t / 0.5),
              alignment: Alignment.bottomCenter,
            )
          else
            // Phase two: the new bottom drops to cover the old one.
            _rotated(
              child: _half(data, to, top: false),
              angle: axis * math.pi / 2 * (1 - (t - 0.5) / 0.5),
              alignment: Alignment.topCenter,
            ),
        ],
      ),
    );
  }

  /// One half of a digit, clipped at the fold line.
  Widget _half(SlotRenderData data, int digit, {required bool top}) => Align(
    alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
    child: ClipRect(
      child: Align(
        alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
        heightFactor: 0.5,
        child: SizedBox(
          width: data.cellWidth,
          height: data.cellHeight,
          child: Center(child: Text('$digit', style: data.textStyle)),
        ),
      ),
    ),
  );

  /// Applies a perspective X-rotation hinged on [alignment].
  Widget _rotated({
    required Widget child,
    required double angle,
    required Alignment alignment,
  }) => Transform(
    alignment: alignment,
    transform: Matrix4.identity()
      ..setEntry(3, 2, 0.0015)
      ..rotateX(angle),
    child: child,
  );
}
