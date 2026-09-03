import 'package:flutter/widgets.dart';

import '../../core/motion_direction.dart';
import '../digit_motion.dart';
import '../slot_render_data.dart';

/// Clean, financial motion: each digit takes the shortest path to its target.
///
/// The default style. A digit travels whichever way is fewer steps, with ties
/// broken by the value's direction so a falling number still visibly falls.
/// Slots are staggered slightly left to right, which reads as the number
/// settling rather than snapping.
class RollingMotion extends DigitMotion {
  /// Creates a rolling motion.
  const RollingMotion({this.staggerAmount = 0.25})
    : assert(
        staggerAmount >= 0 && staggerAmount < 1,
        'staggerAmount must be in [0, 1)',
      );

  /// The fraction of the timeline spread across the slots.
  final double staggerAmount;

  @override
  Duration get defaultDuration => const Duration(milliseconds: 650);

  @override
  Curve get defaultCurve => Curves.easeOutCubic;

  @override
  double localT(
    double globalT,
    int slotIndex,
    int slotCount,
    MotionDirection direction,
  ) =>
      DigitMotion.stagger(globalT, slotIndex, slotCount, amount: staggerAmount);

  @override
  Widget buildSlot(BuildContext context, SlotRenderData data, double t) {
    final double position = DigitMotion.stripPosition(
      data.fromDigit!,
      DigitMotion.shortestDistance(
        data.fromDigit!,
        data.toDigit!,
        data.direction,
      ),
      t,
    );
    return Transform.translate(
      offset: Offset(0, -position * data.cellHeight),
      child: data.strip,
    );
  }
}
