/// Turns a number into the text that will be split into glyph slots.
///
/// This is the lowest layer of the package: it knows nothing about glyphs,
/// motion or widgets, and returns a plain [String]. The core layer is what
/// splits that string into slots, which keeps the dependency arrow pointing one
/// way and makes every formatter testable with a single `expect`.
///
/// Implementations must be deterministic — the same [value] always yields the
/// same text — because the diff between two formatted strings is what drives
/// the animation.
abstract class NumberTextFormatter {
  /// Const constructor so subclasses can be const.
  const NumberTextFormatter();

  /// Formats [value] for display.
  String format(num value);
}
