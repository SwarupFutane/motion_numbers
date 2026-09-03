import 'package:flutter/widgets.dart';

import '../core/glyph_differ.dart';
import '../core/motion_direction.dart';

/// Everything a [DigitMotion] needs to paint one slot.
///
/// The widget layer builds one of these per slot per frame, but the expensive
/// part — [strip] — is built once in `State` and handed through unchanged, so a
/// motion style must never rebuild it.
@immutable
class SlotRenderData {
  /// Creates render data for one slot.
  const SlotRenderData({
    required this.instruction,
    required this.slotIndex,
    required this.slotCount,
    required this.direction,
    required this.cellSize,
    required this.textStyle,
    required this.strip,
    required this.stripRepeats,
    this.color,
  });

  /// What this slot should do: roll, enter, exit or hold.
  final SlotInstruction instruction;

  /// This slot's index in reading order, `0` being leftmost.
  ///
  /// Stagger is computed from this, which is why it is an index into the
  /// rendered row rather than a place value.
  final int slotIndex;

  /// How many slots the row has.
  final int slotCount;

  /// Which way the underlying value moved.
  final MotionDirection direction;

  /// The fixed size of one digit cell, from `DigitMetrics`.
  final Size cellSize;

  /// The resolved text style for this slot.
  final TextStyle textStyle;

  /// The pre-built column of digits, or `null` for a non-digit slot.
  ///
  /// Contains the digits `0`–`9` repeated [stripRepeats] times, each cell
  /// exactly [cellSize] tall, so translating it by `-position * height` shows
  /// the digit at `position`. Built once and reused every frame.
  final Widget? strip;

  /// How many times `0`–`9` is repeated in [strip].
  final int stripRepeats;

  /// A direction tint to apply while the slot is moving, if any.
  final Color? color;

  /// The digit this slot starts on, or `null` if it is not a digit slot.
  int? get fromDigit => switch (instruction) {
    RollSlot(:final int from) => from,
    _ => null,
  };

  /// The digit this slot ends on, or `null` if it is not a digit slot.
  int? get toDigit => switch (instruction) {
    RollSlot(:final int to) => to,
    _ => null,
  };

  /// The height of one digit cell.
  double get cellHeight => cellSize.height;

  /// The width of one digit cell.
  double get cellWidth => cellSize.width;

  /// Whether this slot rolls between two digits.
  bool get isRolling => instruction is RollSlot;
}
