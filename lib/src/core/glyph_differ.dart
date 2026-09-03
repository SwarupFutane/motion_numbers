import 'glyph.dart';

/// What one slot should do during a transition.
///
/// [GlyphDiffer.align] emits exactly one instruction per rendered slot, so the
/// widget layer can map the result straight onto a row of cells.
sealed class SlotInstruction {
  /// Creates an instruction for the slot at [placeIndex].
  const SlotInstruction({required this.placeIndex});

  /// The slot's position counted from the right, `0` being the last character.
  final int placeIndex;
}

/// A digit slot that travels from one digit to another.
final class RollSlot extends SlotInstruction {
  /// Creates a roll from [from] to [to].
  const RollSlot({
    required this.from,
    required this.to,
    required super.placeIndex,
  });

  /// The digit shown before the transition.
  final int from;

  /// The digit shown after the transition.
  final int to;

  /// Whether this slot's digit is unchanged.
  bool get isStill => from == to;

  @override
  String toString() => 'RollSlot($from → $to @$placeIndex)';
}

/// A slot that did not exist before and animates in.
///
/// Produced when the number grows — `999 → 1000` — or when a formatter adds a
/// grouping separator. The slot widens from zero so the row pushes open rather
/// than snapping a character into place.
final class EnterSlot extends SlotInstruction {
  /// Creates an entering slot showing [glyph].
  const EnterSlot({required this.glyph, required super.placeIndex});

  /// The glyph that appears.
  final GlyphSpec glyph;

  @override
  String toString() => 'EnterSlot($glyph)';
}

/// A slot that existed before and animates out.
///
/// Produced when the number shrinks — `1000 → 999` — or loses a separator.
final class ExitSlot extends SlotInstruction {
  /// Creates an exiting slot showing [glyph].
  const ExitSlot({required this.glyph, required super.placeIndex});

  /// The glyph that disappears.
  final GlyphSpec glyph;

  @override
  String toString() => 'ExitSlot($glyph)';
}

/// A non-digit slot that is present before and after, unchanged.
final class StaticSlot extends SlotInstruction {
  /// Creates a static slot showing [char].
  const StaticSlot({required this.char, required super.placeIndex});

  /// The character held by this slot.
  final String char;

  @override
  String toString() => 'StaticSlot($char @$placeIndex)';
}

/// Aligns two glyph lists into per-slot instructions.
///
/// Alignment is **right-anchored**: both lists are walked from `placeIndex 0`
/// outward, so `999 → 1000` rolls the three shared digits and enters only the
/// new leading one. Left-anchored alignment would instead churn every digit,
/// which is the defect this package exists to avoid.
abstract final class GlyphDiffer {
  /// Produces one [SlotInstruction] per rendered slot.
  ///
  /// The result is in reading order (leftmost first) and always has
  /// `max(from.length, to.length)` entries, so the widget layer can render it
  /// as a row without further bookkeeping.
  ///
  /// Slots present in both lists become [RollSlot] (two digits) or
  /// [StaticSlot] (the same non-digit character). Surplus slots become
  /// [EnterSlot] or [ExitSlot]. A slot whose *kind* changes — a digit replaced
  /// by a separator, say — is treated as an [EnterSlot], which keeps the
  /// one-instruction-per-slot invariant intact.
  static List<SlotInstruction> align(List<GlyphSpec> from, List<GlyphSpec> to) {
    final int fromLength = from.length;
    final int toLength = to.length;
    final int slotCount = fromLength > toLength ? fromLength : toLength;

    // Built right to left, then reversed into reading order.
    final List<SlotInstruction> reversed = <SlotInstruction>[];
    for (int place = 0; place < slotCount; place++) {
      final GlyphSpec? before = place < fromLength
          ? from[fromLength - 1 - place]
          : null;
      final GlyphSpec? after = place < toLength
          ? to[toLength - 1 - place]
          : null;
      reversed.add(_instructionFor(before, after, place));
    }
    return reversed.reversed.toList();
  }

  static SlotInstruction _instructionFor(
    GlyphSpec? before,
    GlyphSpec? after,
    int place,
  ) {
    if (after == null) {
      // Only the old list reaches this far: the number shrank.
      return ExitSlot(glyph: before!, placeIndex: place);
    }
    if (before == null) {
      // Only the new list reaches this far: the number grew.
      return EnterSlot(glyph: after, placeIndex: place);
    }
    if (before is DigitGlyph && after is DigitGlyph) {
      return RollSlot(from: before.digit, to: after.digit, placeIndex: place);
    }
    if (before is StaticGlyph &&
        after is StaticGlyph &&
        before.char == after.char) {
      return StaticSlot(char: after.char, placeIndex: place);
    }
    // The slot changed kind, or one separator became another. Replacing it
    // reads as an enter and keeps one instruction per slot.
    return EnterSlot(glyph: after, placeIndex: place);
  }
}
