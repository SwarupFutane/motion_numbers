import 'package:flutter/widgets.dart';

import '../motion/digit_motion.dart';
import '../motion/slot_render_data.dart';

/// One digit slot: a fixed-width window onto a scrolling column of digits.
///
/// The [RepaintBoundary] is load-bearing rather than decorative — without it a
/// single digit repainting dirties the whole row, which is the difference
/// between one cheap layer and a full-row raster every frame.
///
/// Width is fixed by `DigitMetrics`, so the row can never reflow mid-animation.
/// [widthFactor] and [opacity] animate a slot in or out when the number gains
/// or loses digits.
class DigitCell extends StatelessWidget {
  /// Creates a digit cell.
  const DigitCell({
    required this.motion,
    required this.data,
    required this.t,
    this.widthFactor = 1.0,
    this.opacity = 1.0,
    super.key,
  });

  /// The style painting this slot.
  final DigitMotion motion;

  /// Everything the style needs, including the cached digit strip.
  final SlotRenderData data;

  /// This slot's progress, already staggered and eased.
  final double t;

  /// How much of the cell's width is currently occupied, `0` to `1`.
  final double widthFactor;

  /// The slot's opacity, `0` to `1`.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    // The style translates the cached strip; the window clips it to one digit.
    Widget cell = SizedBox(
      width: data.cellWidth,
      height: data.cellHeight,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: data.cellWidth,
          maxWidth: data.cellWidth,
          minHeight: 0,
          maxHeight: double.infinity,
          child: motion.buildSlot(context, data, t),
        ),
      ),
    );

    if (opacity < 1) {
      cell = Opacity(opacity: opacity.clamp(0.0, 1.0), child: cell);
    }
    if (widthFactor < 1) {
      cell = ClipRect(
        child: Align(
          alignment: Alignment.centerRight,
          widthFactor: widthFactor.clamp(0.0, 1.0),
          child: cell,
        ),
      );
    }

    // The strip contains every digit 0-9; announcing it would make a screen
    // reader recite them, so semantics for the number are supplied once by
    // MotionNumber instead.
    return RepaintBoundary(child: ExcludeSemantics(child: cell));
  }
}
