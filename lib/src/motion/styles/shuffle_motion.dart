import 'package:flutter/widgets.dart';

import '../../core/motion_direction.dart';
import '../digit_motion.dart';
import '../slot_render_data.dart';

/// Digits scramble, then resolve — the "decrypting" look.
///
/// For the first [scrambleFraction] of the transition each slot shows
/// pseudo-random digits; after that it rolls from wherever it landed to its
/// target.
///
/// The randomness is *deterministic*: it is a hash of the slot index and the
/// quantised time, not a [Random]. A style that returned fresh noise per call
/// would flicker differently on every repaint and could never be golden-tested.
class ShuffleMotion extends DigitMotion {
  /// Creates a shuffle motion.
  const ShuffleMotion({
    this.scrambleFraction = 0.6,
    this.scrambleSteps = 12,
    this.staggerAmount = 0.3,
  }) : assert(
         scrambleFraction > 0 && scrambleFraction < 1,
         'scrambleFraction must be in (0, 1)',
       ),
       assert(scrambleSteps > 0, 'scrambleSteps must be positive');

  /// How much of the transition is spent scrambling.
  final double scrambleFraction;

  /// How many distinct random digits are shown while scrambling.
  final int scrambleSteps;

  /// The fraction of the timeline spread across the slots.
  final double staggerAmount;

  @override
  Duration get defaultDuration => const Duration(milliseconds: 1100);

  @override
  Curve get defaultCurve => Curves.easeOutQuart;

  @override
  double localT(
    double globalT,
    int slotIndex,
    int slotCount,
    MotionDirection direction,
  ) =>
      DigitMotion.stagger(globalT, slotIndex, slotCount, amount: staggerAmount);

  /// A stable pseudo-random digit for a slot at a scramble step.
  int _scrambled(int slotIndex, int step) {
    // A cheap integer hash; the constants are arbitrary primes.
    int hash = slotIndex * 73856093 ^ step * 19349663;
    hash = (hash ^ (hash >> 13)) * 1274126177;
    return (hash ^ (hash >> 16)).abs() % 10;
  }

  /// The strip position for this slot at [t].
  double _position(SlotRenderData data, double t) {
    if (t < scrambleFraction) {
      final int step = (t / scrambleFraction * scrambleSteps).floor();
      return _scrambled(data.slotIndex, step).toDouble();
    }
    // Settle from the last scrambled digit to the target.
    final int start = _scrambled(data.slotIndex, scrambleSteps - 1);
    final double local = (t - scrambleFraction) / (1 - scrambleFraction);
    return DigitMotion.stripPosition(
      start,
      DigitMotion.shortestDistance(start, data.toDigit!, data.direction),
      local,
    );
  }

  @override
  Widget buildSlot(BuildContext context, SlotRenderData data, double t) =>
      Transform.translate(
        offset: Offset(0, -_position(data, t) * data.cellHeight),
        child: data.strip,
      );

  @override
  int visibleDigit(SlotRenderData data, double t) =>
      _position(data, t).round() % 10;
}
