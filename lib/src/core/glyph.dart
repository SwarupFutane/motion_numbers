/// One rendered slot of a formatted number.
///
/// Formatting produces a `List<GlyphSpec>`; nothing downstream of the
/// formatting layer ever sees a `String`. Slots are indexed from the right by
/// [placeIndex] so that alignment between two numbers can be right-anchored —
/// see `GlyphDiffer`.
sealed class GlyphSpec {
  /// Creates a glyph at [placeIndex].
  const GlyphSpec({required this.placeIndex});

  /// Splits a formatted string into glyph slots.
  ///
  /// Characters `0`–`9` become [DigitGlyph]; everything else — separators,
  /// currency symbols, signs, spaces — becomes [StaticGlyph].
  ///
  /// The returned list is in reading order (leftmost first), while
  /// [placeIndex] counts from the right, so `'1,000'` yields place indices
  /// `4, 3, 2, 1, 0`.
  static List<GlyphSpec> parse(String text) {
    final List<GlyphSpec> glyphs = <GlyphSpec>[];
    final int length = text.length;
    for (int i = 0; i < length; i++) {
      final String char = text[i];
      final int placeIndex = length - 1 - i;
      final int? digit = _digitOf(char);
      glyphs.add(
        digit == null
            ? StaticGlyph(char: char, placeIndex: placeIndex)
            : DigitGlyph(digit: digit, placeIndex: placeIndex),
      );
    }
    return glyphs;
  }

  /// This slot's position counted from the right, `0` being the last character.
  final int placeIndex;

  /// The character this glyph renders.
  String get char;

  static int? _digitOf(String char) {
    final int code = char.codeUnitAt(0);
    const int zero = 0x30;
    const int nine = 0x39;
    if (code < zero || code > nine) {
      return null;
    }
    return code - zero;
  }
}

/// A slot holding a digit `0`–`9`, which can roll to another digit.
final class DigitGlyph extends GlyphSpec {
  /// Creates a digit glyph.
  const DigitGlyph({required this.digit, required super.placeIndex});

  /// The digit value, `0`–`9`.
  final int digit;

  @override
  String get char => '$digit';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DigitGlyph &&
          other.digit == digit &&
          other.placeIndex == placeIndex;

  @override
  int get hashCode => Object.hash(digit, placeIndex);

  @override
  String toString() => 'DigitGlyph($digit @$placeIndex)';
}

/// A slot holding a non-digit character such as `,` `.` `₹` `%` or `-`.
///
/// Static glyphs are real slots rather than decoration, so a grouping change
/// animates a separator in or out instead of snapping it into existence.
final class StaticGlyph extends GlyphSpec {
  /// Creates a static glyph.
  const StaticGlyph({required String char, required super.placeIndex})
    : _char = char;

  final String _char;

  @override
  String get char => _char;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaticGlyph &&
          other._char == _char &&
          other.placeIndex == placeIndex;

  @override
  int get hashCode => Object.hash(_char, placeIndex);

  @override
  String toString() => 'StaticGlyph($_char @$placeIndex)';
}
