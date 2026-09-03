import 'number_text_formatter.dart';

/// Which set of magnitude suffixes a [CompactFormatter] uses.
enum CompactScale {
  /// Thousand, million, billion, trillion: `K`, `M`, `B`, `T`.
  western,

  /// Thousand, lakh, crore: `K`, `L`, `Cr`.
  ///
  /// One lakh is 100,000 and one crore is 10,000,000, so `1240000` compacts to
  /// `12.4L` rather than `1.2M`.
  indian,
}

/// Shortens large numbers to a magnitude suffix: `1.2K`, `1.2M`, `12.4L`.
///
/// Compact text changes width as it crosses a magnitude boundary, which the
/// right-anchored diff handles as entering and exiting slots.
class CompactFormatter extends NumberTextFormatter {
  /// Creates a compact formatter.
  const CompactFormatter({
    this.scale = CompactScale.western,
    this.fractionDigits = 1,
    this.trimTrailingZeros = true,
    this.decimalSeparator = '.',
    this.prefix = '',
    this.suffix = '',
  }) : assert(fractionDigits >= 0, 'fractionDigits must not be negative');

  /// Which suffix set to use.
  final CompactScale scale;

  /// Digits kept after the decimal separator, before any trimming.
  final int fractionDigits;

  /// Whether to drop a trailing `.0`, so `1000` reads `1K` rather than `1.0K`.
  final bool trimTrailingZeros;

  /// The character separating the integer and fractional parts.
  final String decimalSeparator;

  /// Text placed before the number.
  final String prefix;

  /// Text placed after the suffix.
  final String suffix;

  static const List<(num, String)> _western = <(num, String)>[
    (1000000000000, 'T'),
    (1000000000, 'B'),
    (1000000, 'M'),
    (1000, 'K'),
  ];

  static const List<(num, String)> _indian = <(num, String)>[
    (10000000, 'Cr'),
    (100000, 'L'),
    (1000, 'K'),
  ];

  @override
  String format(num value) {
    final bool isNegative = value.isNegative && value != 0;
    final num magnitude = value.abs();

    final List<(num, String)> thresholds = switch (scale) {
      CompactScale.western => _western,
      CompactScale.indian => _indian,
    };

    for (final (num threshold, String unit) in thresholds) {
      if (magnitude >= threshold) {
        return _assemble(
          isNegative: isNegative,
          number: magnitude / threshold,
          unit: unit,
        );
      }
    }
    return _assemble(isNegative: isNegative, number: magnitude, unit: '');
  }

  String _assemble({
    required bool isNegative,
    required num number,
    required String unit,
  }) {
    // Whole numbers below the smallest threshold keep their exact value; only
    // scaled values carry a fraction.
    final String fixed = unit.isEmpty && number is int
        ? '$number'
        : number.toStringAsFixed(fractionDigits);
    return '$prefix${isNegative ? '-' : ''}${_trim(fixed)}$unit$suffix';
  }

  String _trim(String fixed) {
    String result = fixed;
    if (trimTrailingZeros && result.contains('.')) {
      result = result.replaceFirst(RegExp(r'\.?0+$'), '');
    }
    return decimalSeparator == '.'
        ? result
        : result.replaceFirst('.', decimalSeparator);
  }
}
