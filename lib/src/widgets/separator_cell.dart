import 'package:flutter/widgets.dart';

/// One non-digit slot: a separator, currency symbol, sign or space.
///
/// Separators are real slots rather than decoration, so a grouping change
/// (`9,999 → 10,000`) animates the comma into place instead of snapping it
/// there. [widthFactor] drives that, sized against the character's own width
/// rather than a digit's.
class SeparatorCell extends StatelessWidget {
  /// Creates a separator cell.
  const SeparatorCell({
    required this.char,
    required this.textStyle,
    this.widthFactor = 1.0,
    this.opacity = 1.0,
    super.key,
  });

  /// The character to render.
  final String char;

  /// The style to render it in.
  final TextStyle textStyle;

  /// How much of the character's width is currently occupied, `0` to `1`.
  final double widthFactor;

  /// The slot's opacity, `0` to `1`.
  final double opacity;

  @override
  Widget build(BuildContext context) {
    Widget cell = Text(char, style: textStyle, textAlign: TextAlign.center);

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

    return ExcludeSemantics(child: cell);
  }
}
