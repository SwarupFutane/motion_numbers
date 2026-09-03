import 'package:flutter/widgets.dart';

import '../core/motion_direction.dart';
import 'slot_render_data.dart';

/// The strategy contract every motion style implements.
///
/// A style decides three things and nothing else: the **path** a digit takes
/// through `0`–`9`, the **easing** along that path, and the **stagger** between
/// neighbouring slots. Everything above this interface — layout, clipping,
/// metrics, semantics, the single [AnimationController] — is shared.
///
/// The contract is deliberately wide enough that adding a style is adding one
/// file. If a new style cannot be expressed here, widen this interface rather
/// than special-casing the style in the widget layer.
abstract class DigitMotion {
  /// Const constructor so styles can be const singletons.
  const DigitMotion();

  /// How long a transition lasts when the caller does not override it.
  Duration get defaultDuration;

  /// The easing applied to the global animation for this style.
  Curve get defaultCurve;

  /// How many times `0`–`9` must be repeated in the digit strip.
  ///
  /// Two is enough for any path that travels at most one full revolution in
  /// either direction. Styles that spin further — `slotMachine` — need more,
  /// and declare it here so the widget layer never has to know which style it
  /// is building for.
  int get stripRepeats => 2;

  /// Maps the global animation value to this slot's own progress.
  ///
  /// The default is the identity: every slot moves together. Override to
  /// stagger. The result should stay within `[0, 1]`, though styles that
  /// overshoot (`elastic`) may exceed it after their curve is applied.
  double localT(
    double globalT,
    int slotIndex,
    int slotCount,
    MotionDirection direction,
  ) => globalT;

  /// Paints one slot at progress [t].
  ///
  /// `data.strip` is the cached digit column — translate or clip it, never
  /// rebuild it.
  Widget buildSlot(BuildContext context, SlotRenderData data, double t);

  /// Which digit is on screen at progress [t].
  ///
  /// Used to snapshot what the user can currently see when a value changes
  /// mid-flight, so the replacement animation starts from the displayed digits
  /// rather than from the abandoned target. The default assumes the shortest
  /// path; a style that travels differently should override it.
  int visibleDigit(SlotRenderData data, double t) {
    final int from = data.fromDigit!;
    final double distance = shortestDistance(
      from,
      data.toDigit!,
      data.direction,
    );
    return stripPosition(from, distance, t).round() % 10;
  }

  /// Spreads slots across the timeline, left to right.
  ///
  /// [amount] is the fraction of the timeline consumed by offsets: `0` moves
  /// every slot together, `0.5` gives the last slot a half-timeline head start
  /// on finishing. The returned value is clamped to `[0, 1]`.
  ///
  /// Pass [reverse] to stagger right to left instead.
  static double stagger(
    double globalT,
    int slotIndex,
    int slotCount, {
    required double amount,
    bool reverse = false,
  }) {
    assert(amount >= 0 && amount < 1, 'amount must be in [0, 1)');
    if (slotCount <= 1 || amount == 0) {
      return globalT.clamp(0.0, 1.0);
    }
    final int index = reverse ? slotCount - 1 - slotIndex : slotIndex;
    final double delay = amount * (index / (slotCount - 1));
    final double span = 1 - amount;
    return ((globalT - delay) / span).clamp(0.0, 1.0);
  }

  /// The signed number of steps along the shortest path from [from] to [to].
  ///
  /// A tie — exactly five steps either way — is broken by [direction], so a
  /// falling value still falls.
  static double shortestDistance(int from, int to, MotionDirection direction) {
    final int up = (to - from) % 10;
    final int down = up == 0 ? 0 : up - 10;
    if (up == -down) {
      return direction.isDown ? down.toDouble() : up.toDouble();
    }
    return up <= -down ? up.toDouble() : down.toDouble();
  }

  /// The signed number of steps travelling only in [direction].
  ///
  /// Unlike [shortestDistance] this never takes a shortcut against the value's
  /// direction, so digits wrap `9 → 0` with a carry the way a mechanical dial
  /// does.
  static double continuousDistance(
    int from,
    int to,
    MotionDirection direction,
  ) {
    if (direction.isNone) {
      return shortestDistance(from, to, direction);
    }
    final int up = (to - from) % 10;
    return direction.isUp ? up.toDouble() : (up == 0 ? 0 : up - 10).toDouble();
  }

  /// The strip position for a slot partway along its path.
  ///
  /// Returns an index into the repeated digit strip, so translating the strip
  /// by `-position * cellHeight` shows the right digit. Downward paths start a
  /// revolution higher, which keeps the position positive without needing a
  /// third copy of the strip.
  static double stripPosition(int from, double distance, double t) {
    final double base = distance < 0 ? from + 10.0 : from.toDouble();
    return base + distance * t;
  }
}
