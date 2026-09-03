import 'number_text_formatter.dart';

/// A dependency-free formatter with fixed-size digit grouping.
///
/// This is the default formatter, and the reason `intl` is optional in spirit:
/// nothing here touches it. Groups are a fixed width — three digits — so it
/// covers the common Western case. For locale-correct grouping, including the
/// Indian `1,24,350` pattern, use `IntlFormatter`.
class PlainFormatter extends NumberTextFormatter {
  /// Creates a plain formatter.
  const PlainFormatter({
    this.decimalDigits = 0,
    this.groupSeparator = ',',
    this.decimalSeparator = '.',
    this.prefix = '',
    this.suffix = '',
    this.grouped = true,
  }) : assert(decimalDigits >= 0, 'decimalDigits must not be negative');

  /// How many digits to show after the decimal separator.
  final int decimalDigits;

  /// The character inserted between groups of three integer digits.
  final String groupSeparator;

  /// The character separating the integer and fractional parts.
  final String decimalSeparator;

  /// Text placed before the number, such as a currency symbol.
  final String prefix;

  /// Text placed after the number, such as `%`.
  final String suffix;

  /// Whether to insert [groupSeparator] between groups of three digits.
  final bool grouped;

  @override
  String format(num value) {
    final bool isNegative = value.isNegative && value != 0;
    final String fixed = value.abs().toStringAsFixed(decimalDigits);

    final int pointIndex = fixed.indexOf('.');
    final String integerPart = pointIndex == -1
        ? fixed
        : fixed.substring(0, pointIndex);
    final String fractionPart = pointIndex == -1
        ? ''
        : fixed.substring(pointIndex + 1);

    final StringBuffer buffer = StringBuffer()
      ..write(prefix)
      ..write(isNegative ? '-' : '')
      ..write(grouped ? _group(integerPart) : integerPart);
    if (fractionPart.isNotEmpty) {
      buffer
        ..write(decimalSeparator)
        ..write(fractionPart);
    }
    return (buffer..write(suffix)).toString();
  }

  /// Inserts [groupSeparator] every three digits, counting from the right.
  String _group(String digits) {
    if (digits.length <= 3) {
      return digits;
    }
    final StringBuffer buffer = StringBuffer();
    final int leading = digits.length % 3;
    if (leading != 0) {
      buffer.write(digits.substring(0, leading));
    }
    for (int i = leading; i < digits.length; i += 3) {
      if (buffer.isNotEmpty) {
        buffer.write(groupSeparator);
      }
      buffer.write(digits.substring(i, i + 3));
    }
    return buffer.toString();
  }
}
