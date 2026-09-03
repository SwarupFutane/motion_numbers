import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/motion_direction.dart';
import '../digit_motion.dart';
import '../slot_render_data.dart';

/// Rolling with overshoot and a small scale pop. Bouncy and gamified.
///
/// The overshoot comes from [Curves.elasticOut], which returns values above
/// `1`. The stagger deliberately does *not* clamp them — clamping would flatten
/// the bounce into an ordinary ease and quietly turn this style into `rolling`.
class ElasticMotion extends DigitMotion {
  /// Creates an elastic motion.
  const ElasticMotion({this.staggerAmount = 0.2, this.popScale = 0.12})
    : assert(
        staggerAmount >= 0 && staggerAmount < 1,
        'staggerAmount must be in [0, 1)',
      );

  /// The fraction of the timeline spread across the slots.
  final double staggerAmount;

  /// How much the digit swells at the midpoint, as a fraction of its size.
  final double popScale;

  @override
  Duration get defaultDuration => const Duration(milliseconds: 1000);

  @override
  Curve get defaultCurve => Curves.elasticOut;

  @override
  double localT(
    double globalT,
    int slotIndex,
    int slotCount,
    MotionDirection direction,
  ) => DigitMotion.stagger(
    globalT,
    slotIndex,
    slotCount,
    amount: staggerAmount,
    allowOvershoot: true,
  );

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

    // Peaks mid-flight and returns to exactly 1, so the resting size matches
    // every other style.
    final double pop = 1 + math.sin(t.clamp(0.0, 1.0) * math.pi) * popScale;

    return Transform.scale(
      scale: pop,
      child: Transform.translate(
        offset: Offset(0, -position * data.cellHeight),
        child: data.strip,
      ),
    );
  }
}
