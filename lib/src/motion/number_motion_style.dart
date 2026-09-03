import 'digit_motion.dart';
import 'styles/rolling_motion.dart';

/// The built-in motion styles.
///
/// This enum is ergonomic sugar, not a ceiling: pass a `motion:` of your own to
/// `MotionNumber` and it bypasses this entirely.
enum NumberMotionStyle {
  /// Shortest path, direction-aware. Clean and financial. The default.
  rolling,

  /// A mechanical dial that always travels continuously, carrying `9 → 0`.
  odometer,

  /// Extra revolutions before settling, staggered hard. Casino reveal.
  slotMachine,

  /// Split-flap board: the old digit folds away, the new one falls in.
  flip,

  /// Rolling with a sinusoidal offset across the row. Playful.
  wave,

  /// Random digits for the first part of the transition, then a settle.
  shuffle,

  /// Rolling with overshoot and a small scale pop. Bouncy.
  elastic,
}

/// Maps a [NumberMotionStyle] to the strategy that implements it.
///
/// Every style is a const singleton, so resolving costs nothing per frame.
DigitMotion resolveMotionStyle(NumberMotionStyle style) => switch (style) {
  // Step 8 replaces these placeholders with the real implementations. The
  // widget layer must not need editing when that happens.
  NumberMotionStyle.rolling => const RollingMotion(),
  NumberMotionStyle.odometer => const RollingMotion(),
  NumberMotionStyle.slotMachine => const RollingMotion(),
  NumberMotionStyle.flip => const RollingMotion(),
  NumberMotionStyle.wave => const RollingMotion(),
  NumberMotionStyle.shuffle => const RollingMotion(),
  NumberMotionStyle.elastic => const RollingMotion(),
};
