import 'package:flutter/widgets.dart';

/// Measures and caches the size of a digit cell for a given [TextStyle].
///
/// Proportional fonts give `1` and `8` different advance widths, so a row that
/// sizes itself to its current digits twitches on every frame. Every digit cell
/// is instead given the width of the *widest* digit in the style, measured once
/// and cached library-wide, which makes reflow mid-animation impossible.
///
/// With `tabularFigures` enabled — the default — [withTabularFigures] adds
/// [FontFeature.tabularFigures], which makes the measurement exact rather than
/// merely safe on fonts that support the feature.
abstract final class DigitMetrics {
  static final Map<_MetricsKey, Size> _cache = <_MetricsKey, Size>{};

  /// The size of one digit cell in [style].
  ///
  /// [Size.width] is the widest advance width among the digits `0`–`9`;
  /// [Size.height] is the line height. Results are cached, so repeated calls
  /// with an equal [style] and [textScaler] cost a map lookup.
  static Size measure(
    TextStyle style, {
    TextScaler textScaler = TextScaler.noScaling,
  }) {
    final _MetricsKey key = _MetricsKey(style, textScaler);
    final Size? cached = _cache[key];
    if (cached != null) {
      return cached;
    }

    double width = 0;
    double height = 0;
    final TextPainter painter = TextPainter(
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    );
    for (int digit = 0; digit <= 9; digit++) {
      painter.text = TextSpan(text: '$digit', style: style);
      painter.layout();
      if (painter.width > width) {
        width = painter.width;
      }
      if (painter.height > height) {
        height = painter.height;
      }
    }
    painter.dispose();

    final Size size = Size(width, height);
    _cache[key] = size;
    return size;
  }

  /// Returns [style] with tabular (fixed-advance) figures enabled.
  ///
  /// Existing font features are preserved. If tabular figures are already
  /// requested, [style] is returned unchanged.
  static TextStyle withTabularFigures(TextStyle style) {
    final List<FontFeature> features =
        style.fontFeatures ?? const <FontFeature>[];
    if (features.any((FontFeature f) => f.feature == 'tnum')) {
      return style;
    }
    return style.copyWith(
      fontFeatures: <FontFeature>[
        ...features,
        const FontFeature.tabularFigures(),
      ],
    );
  }

  /// The number of entries currently cached. Exposed for tests.
  @visibleForTesting
  static int get cacheSize => _cache.length;

  /// Empties the measurement cache.
  ///
  /// Only useful in tests, or after a font is loaded at runtime that changes
  /// the metrics of a style already measured.
  static void clearCache() => _cache.clear();
}

/// Cache key pairing a text style with the scaler applied to it.
@immutable
class _MetricsKey {
  const _MetricsKey(this.style, this.textScaler);

  final TextStyle style;
  final TextScaler textScaler;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MetricsKey &&
          other.style == style &&
          other.textScaler == textScaler;

  @override
  int get hashCode => Object.hash(style, textScaler);
}
