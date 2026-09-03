import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/motion_direction.dart';
import '../digit_motion.dart';
import '../slot_render_data.dart';

/// Rolling with a sinusoidal lift travelling across the row.
///
/// The phase offset comes from the slot index, so the row undulates instead of
/// moving as a block. The lift peaks mid-transition and returns to zero, which
/// keeps the final layout identical to every other style.
class WaveMotion extends DigitMotion {
  /// Creates a wave motion.
  const WaveMotion({this.staggerAmount = 0.3, this.amplitude = 0.18})
    : assert(
        staggerAmount >= 0 && staggerAmount < 1,
        'staggerAmount must be in [0, 1)',
      );

  /// The fraction of the timeline spread across the slots.
  final double staggerAmount;

  /// Peak vertical lift, as a fraction of the cell height.
  final double amplitude;

  @override
  Duration get defaultDuration => const Duration(milliseconds: 900);

  @override
  Curve get defaultCurve => Curves.easeOutSine;

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

    // Zero at both ends, so the wave never displaces the resting layout.
    final double lift =
        math.sin(t * math.pi) *
        math.sin(data.slotIndex * 0.9) *
        amplitude *
        data.cellHeight;

    return Transform.translate(
      offset: Offset(0, -position * data.cellHeight + lift),
      child: data.strip,
    );
  }
}
