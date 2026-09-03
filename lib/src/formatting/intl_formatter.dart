import 'package:intl/intl.dart';

import 'number_text_formatter.dart';

/// A formatter backed by an `intl` [NumberFormat].
///
/// This is what makes locale-correct grouping possible. Indian English groups
/// the leading digits in pairs, so `124350` is `1,24,350` rather than
/// `124,350` — a pattern no fixed-width grouper can produce.
///
/// ```dart
/// IntlFormatter.currency(locale: 'en_IN', symbol: '₹').format(124350);
/// // ₹1,24,350
/// ```
///
/// Locale auto-detection and currency conversion are deliberately out of
/// scope: pass whichever [NumberFormat] you want.
class IntlFormatter extends NumberTextFormatter {
  /// Wraps an existing [NumberFormat].
  const IntlFormatter(this.numberFormat);

  /// A decimal formatter for [locale], with grouping.
  ///
  /// Passing `'en_IN'` yields the Indian lakh/crore grouping.
  IntlFormatter.decimal({String? locale})
    : numberFormat = NumberFormat.decimalPattern(locale);

  /// A currency formatter for [locale].
  ///
  /// [symbol] overrides the locale's default currency symbol, and
  /// [decimalDigits] its default precision — pass `0` for whole-rupee or
  /// whole-dollar display.
  IntlFormatter.currency({String? locale, String? symbol, int? decimalDigits})
    : numberFormat = NumberFormat.currency(
        locale: locale,
        symbol: symbol,
        decimalDigits: decimalDigits,
      );

  /// A percentage formatter for [locale].
  IntlFormatter.percent({String? locale})
    : numberFormat = NumberFormat.percentPattern(locale);

  /// The underlying `intl` format.
  final NumberFormat numberFormat;

  @override
  String format(num value) => numberFormat.format(value);
}
