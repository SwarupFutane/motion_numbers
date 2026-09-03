import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/src/core/glyph.dart';
import 'package:motion_number/src/core/glyph_differ.dart';

/// Renders instructions compactly so failures are readable.
String _describe(List<SlotInstruction> instructions) => instructions
    .map(
      (SlotInstruction i) => switch (i) {
        RollSlot(:final int from, :final int to) => 'R$from>$to',
        EnterSlot(glyph: DigitGlyph(:final int digit)) => 'E$digit',
        EnterSlot(glyph: StaticGlyph(:final String char)) => 'E$char',
        ExitSlot(glyph: DigitGlyph(:final int digit)) => 'X$digit',
        ExitSlot(glyph: StaticGlyph(:final String char)) => 'X$char',
        StaticSlot(:final String char) => 'S$char',
      },
    )
    .join(' ');

List<SlotInstruction> diff(String from, String to) =>
    GlyphDiffer.align(GlyphSpec.parse(from), GlyphSpec.parse(to));

void main() {
  group('GlyphSpec.parse', () {
    test('splits a formatted string into digit and static slots', () {
      final List<GlyphSpec> glyphs = GlyphSpec.parse('1,000');

      expect(glyphs, hasLength(5));
      expect(glyphs[0], isA<DigitGlyph>());
      expect(glyphs[1], isA<StaticGlyph>());
      expect((glyphs[0] as DigitGlyph).digit, 1);
      expect((glyphs[1] as StaticGlyph).char, ',');
    });

    test('indexes placeIndex from the right, 0 being the last character', () {
      final List<GlyphSpec> glyphs = GlyphSpec.parse('1,000');

      expect(glyphs.map((GlyphSpec g) => g.placeIndex).toList(), <int>[
        4,
        3,
        2,
        1,
        0,
      ]);
    });

    test('treats currency and sign characters as static slots', () {
      final List<GlyphSpec> glyphs = GlyphSpec.parse('-₹5');

      expect(glyphs[0], isA<StaticGlyph>());
      expect(glyphs[1], isA<StaticGlyph>());
      expect(glyphs[2], isA<DigitGlyph>());
    });

    test('returns an empty list for an empty string', () {
      expect(GlyphSpec.parse(''), isEmpty);
    });
  });

  group('GlyphDiffer.align — right anchoring', () {
    test('999 -> 1000 produces exactly one EnterSlot', () {
      // The load-bearing assertion of this layer. Left-anchored alignment would
      // churn every digit; right-anchored touches only the new leading one.
      final List<SlotInstruction> result = diff('999', '1000');

      expect(_describe(result), 'E1 R9>0 R9>0 R9>0');
      expect(result.whereType<EnterSlot>(), hasLength(1));
      expect(result.whereType<ExitSlot>(), isEmpty);
    });

    test('1000 -> 999 produces exactly one ExitSlot', () {
      final List<SlotInstruction> result = diff('1000', '999');

      expect(_describe(result), 'X1 R0>9 R0>9 R0>9');
      expect(result.whereType<ExitSlot>(), hasLength(1));
      expect(result.whereType<EnterSlot>(), isEmpty);
    });

    test('aligns shared trailing digits rather than leading ones', () {
      // Left-anchored would pair 1<->2 and 2<->3; right-anchored pairs the
      // shared tail and enters only the new leading digit.
      final List<SlotInstruction> result = diff('12', '123');

      expect(_describe(result), 'E1 R1>2 R2>3');
    });

    test('a same-width change rolls every differing digit in place', () {
      expect(_describe(diff('19', '20')), 'R1>2 R9>0');
    });

    test('an unchanged value still emits a roll for each digit', () {
      expect(_describe(diff('42', '42')), 'R4>4 R2>2');
    });

    test('separators that persist become StaticSlot, not RollSlot', () {
      expect(_describe(diff('1,234', '5,678')), 'R1>5 S, R2>6 R3>7 R4>8');
    });

    test('a new grouping separator enters alongside the new digit', () {
      // 9,999 -> 10,000: the comma stays put and one digit enters.
      expect(_describe(diff('9,999', '10,000')), 'E1 R9>0 S, R9>0 R9>0 R9>0');
    });

    test('999 -> 1,000 enters both the comma and the leading digit', () {
      // With grouping enabled the same numeric step yields two EnterSlots: the
      // digit and the separator. The "exactly one EnterSlot" rule is about the
      // differ itself, on ungrouped glyphs.
      final List<SlotInstruction> result = diff('999', '1,000');

      expect(_describe(result), 'E1 E, R9>0 R9>0 R9>0');
      expect(result.whereType<EnterSlot>(), hasLength(2));
    });

    test('handles the Indian grouping example from the architecture doc', () {
      expect(
        _describe(diff('₹1,24,350', '₹1,31,890')),
        'S₹ R1>1 S, R2>3 R4>1 S, R3>8 R5>9 R0>0',
      );
    });
  });

  group('GlyphDiffer.align — invariants', () {
    test('emits exactly one instruction per rendered slot', () {
      for (final (String a, String b) in const <(String, String)>[
        ('999', '1000'),
        ('1000', '999'),
        ('1,234', '5,678'),
        ('', '5'),
        ('5', ''),
        ('₹1,24,350', '₹1,31,890'),
      ]) {
        final int expected =
            GlyphSpec.parse(a).length > GlyphSpec.parse(b).length
            ? GlyphSpec.parse(a).length
            : GlyphSpec.parse(b).length;
        expect(
          GlyphDiffer.align(GlyphSpec.parse(a), GlyphSpec.parse(b)),
          hasLength(expected),
          reason: '"$a" -> "$b"',
        );
      }
    });

    test('returns instructions in reading order, leftmost first', () {
      final List<SlotInstruction> result = diff('12', '99');

      expect((result[0] as RollSlot).from, 1);
      expect((result[1] as RollSlot).from, 2);
    });

    test('placeIndex counts from the right across the result', () {
      final List<SlotInstruction> result = diff('999', '1000');

      expect(result.map((SlotInstruction i) => i.placeIndex).toList(), <int>[
        3,
        2,
        1,
        0,
      ]);
    });

    test('growing from empty enters every slot', () {
      expect(_describe(diff('', '12')), 'E1 E2');
    });

    test('shrinking to empty exits every slot', () {
      expect(_describe(diff('12', '')), 'X1 X2');
    });

    test('a digit replaced by a separator enters rather than rolling', () {
      // Kind mismatch: one instruction per slot is preserved by treating the
      // replacement as an enter.
      final List<SlotInstruction> result = diff('1.5', '15');

      expect(result, hasLength(3));
      expect(_describe(result), 'X1 E1 R5>5');
    });
  });
}
