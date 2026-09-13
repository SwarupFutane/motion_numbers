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

    // A rising value folds downward, the way a split-flap board turns. A
    // falling value runs the same sequence mirrored — the old bottom lifts,
    // then the new top settles — so a decrease reads as a decrease.
    final bool down = data.direction.isDown;

    // Phase one covers the first half of the timeline, phase two the second.
    // Each flap turns a quarter-turn about the fold line, edge-on at the seam.
    final bool phaseOne = t < 0.5;
    final double fold = phaseOne ? t / 0.5 : 1 - (t - 0.5) / 0.5;
    final double angle = math.pi / 2 * fold.clamp(0.0, 1.0);

    // Rising: the old top folds down, then the new bottom lands.
    // Falling: the old bottom lifts up, then the new top lands.
    final bool flapIsTop = down != phaseOne;
    final int flapDigit = phaseOne ? from : to;

    // The static halves: what the flap uncovers in phase one, and what it
    // lands on in phase two. For a rising value that is the new top over the
    // old bottom; a falling value is the mirror image.
    final int topDigit = down ? from : to;
    final int bottomDigit = down ? to : from;

    // A real flap is an opaque card, so the half behind it is hidden wherever
    // the card is. Glyphs here are transparent, so that half is clipped to the
    // band the flap has not reached — otherwise the two digits show through
    // each other for the whole transition.
    final double seam = data.cellHeight / 2;
    final double reach = _projectedReach(seam, angle);

    Widget covered(int digit, {required bool top}) => ClipRect(
      clipper: _BandClipper(
        top ? 0 : seam + reach,
        top ? seam - reach : data.cellHeight,
      ),
      child: _half(data, digit, top: top),
    );

    // A positive X-rotation tips a top half's free edge toward the viewer and
    // a bottom half's away, so the bottom takes the negative angle — both
    // flaps swing out in front of the board rather than behind it.
    final Widget flap = _rotated(
      _half(data, flapDigit, top: flapIsTop),
      flapIsTop ? angle : -angle,
    );

    return SizedBox(
      width: data.cellWidth,
      height: data.cellHeight,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (flapIsTop)
            covered(topDigit, top: true)
          else
            _half(data, topDigit, top: true),
          if (flapIsTop)
            _half(data, bottomDigit, top: false)
          else
            covered(bottomDigit, top: false),
          flap,
        ],
      ),
    );
  }

  /// The perspective used by [_rotated], as the `(3, 2)` matrix entry.
  static const double _perspective = 0.0015;

  /// How far from the seam a flap of [halfHeight] reaches when turned by
  /// [angle], after perspective.
  ///
  /// The flap swings toward the viewer, so perspective magnifies it: its free
  /// edge lands a little further from the seam than `cos(angle)` alone says.
  /// Clipping to the unmagnified reach would leave a sliver of overlap.
  static double _projectedReach(double halfHeight, double angle) {
    final double w = 1 - _perspective * halfHeight * math.sin(angle);
    if (w <= 0) {
      return halfHeight;
    }
    return (halfHeight * math.cos(angle) / w).clamp(0.0, halfHeight);
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

  /// Applies a perspective X-rotation hinged on the fold line.
  ///
  /// [child] is a [_half], which fills the whole cell and places its visible
  /// half against one edge — so the fold line is the cell's centre, not the
  /// edge the half is aligned to. Hinging on that edge instead swings the flap
  /// across the other half and the two digits pile into each other.
  Widget _rotated(Widget child, double angle) => Transform(
    alignment: Alignment.center,
    transform: Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateX(angle),
    child: child,
  );
}

/// Clips to a horizontal band of the cell, from [top] to [bottom].
class _BandClipper extends CustomClipper<Rect> {
  const _BandClipper(this.top, this.bottom);

  final double top;
  final double bottom;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, top, size.width, math.max(top, bottom));

  @override
  bool shouldReclip(_BandClipper oldClipper) =>
      oldClipper.top != top || oldClipper.bottom != bottom;
}
