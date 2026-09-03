import 'package:flutter/widgets.dart';

import '../../core/motion_direction.dart';
import '../digit_motion.dart';
import '../slot_render_data.dart';

/// A casino reveal: each slot spins several extra revolutions before settling.
///
/// The number of extra revolutions varies per slot, so the row lands left to
/// right rather than all at once. This is the style that needs a longer strip —
/// [stripRepeats] is six rather than two — which it declares rather than
/// requiring the widget layer to know.
class SlotMachineMotion extends DigitMotion {
  /// Creates a slot-machine motion.
  const SlotMachineMotion({this.minRevolutions = 2, this.staggerAmount = 0.55})
    : assert(minRevolutions >= 0, 'minRevolutions must not be negative'),
      assert(
        staggerAmount >= 0 && staggerAmount < 1,
        'staggerAmount must be in [0, 1)',
      );

  /// The fewest extra revolutions any slot makes.
  final int minRevolutions;

  /// The fraction of the timeline spread across the slots.
  final double staggerAmount;

  /// Six copies of `0`–`9`, enough for four extra revolutions plus the path.
  @override
  int get stripRepeats => 6;

  @override
  Duration get defaultDuration => const Duration(milliseconds: 1400);

  @override
  Curve get defaultCurve => Curves.decelerate;

  @override
  double localT(
    double globalT,
    int slotIndex,
    int slotCount,
    MotionDirection direction,
  ) =>
      DigitMotion.stagger(globalT, slotIndex, slotCount, amount: staggerAmount);

  /// Two to four extra revolutions, fixed per slot so the spin is stable
  /// across frames and reproducible in golden tests.
  int _revolutions(int slotIndex) => minRevolutions + (slotIndex % 3);

  double _distance(SlotRenderData data) {
    final double base = DigitMotion.continuousDistance(
      data.fromDigit!,
      data.toDigit!,
      data.direction,
    );
    final double spin = _revolutions(data.slotIndex) * 10.0;
    return data.direction.isDown ? base - spin : base + spin;
  }

  @override
  Widget buildSlot(BuildContext context, SlotRenderData data, double t) =>
      Transform.translate(
        offset: Offset(
          0,
          -DigitMotion.stripPosition(data.fromDigit!, _distance(data), t) *
              data.cellHeight,
        ),
        child: data.strip,
      );

  @override
  int visibleDigit(SlotRenderData data, double t) =>
      DigitMotion.stripPosition(data.fromDigit!, _distance(data), t).round() %
      10;
}
