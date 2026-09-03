/// Direction-aware animated numbers for Flutter.
///
/// A formatted number is treated as a stable list of glyph slots. Each slot
/// animates on its own timeline, alignment is right-anchored so `999 → 1000`
/// enters one digit rather than churning four, and the motion knows whether the
/// value rose or fell.
///
/// ```dart
/// MotionNumber(value: 131890, style: NumberMotionStyle.rolling)
/// ```
///
/// This is the only import; everything under `src/` is private, which is what
/// keeps the semver contract small.
library;

// Core values.
export 'src/core/digit_metrics.dart' show DigitMetrics;
export 'src/core/glyph.dart' show DigitGlyph, GlyphSpec, StaticGlyph;
export 'src/core/glyph_differ.dart'
    show
        EnterSlot,
        ExitSlot,
        GlyphDiffer,
        RollSlot,
        SlotInstruction,
        StaticSlot;
export 'src/core/motion_direction.dart' show MotionDirection;
export 'src/core/value_transition.dart' show ValueTransition;

// Formatting.
export 'src/formatting/compact_formatter.dart'
    show CompactFormatter, CompactScale;
export 'src/formatting/intl_formatter.dart' show IntlFormatter;
export 'src/formatting/number_text_formatter.dart' show NumberTextFormatter;
export 'src/formatting/plain_formatter.dart' show PlainFormatter;

// Motion contract and the built-in styles.
export 'src/motion/digit_motion.dart' show DigitMotion;
export 'src/motion/number_motion_style.dart'
    show NumberMotionStyle, resolveMotionStyle;
export 'src/motion/slot_render_data.dart' show SlotRenderData;
export 'src/motion/styles/elastic_motion.dart' show ElasticMotion;
export 'src/motion/styles/flip_motion.dart' show FlipMotion;
export 'src/motion/styles/odometer_motion.dart' show OdometerMotion;
export 'src/motion/styles/rolling_motion.dart' show RollingMotion;
export 'src/motion/styles/shuffle_motion.dart' show ShuffleMotion;
export 'src/motion/styles/slot_machine_motion.dart' show SlotMachineMotion;
export 'src/motion/styles/wave_motion.dart' show WaveMotion;

// Theme.
export 'src/theme/direction_colors.dart' show DirectionColors;
export 'src/theme/motion_number_theme.dart' show MotionNumberTheme;

// Widgets.
export 'src/widgets/motion_delta.dart' show MotionDelta;
export 'src/widgets/motion_number.dart' show MotionNumber;
export 'src/widgets/motion_number_scope.dart' show MotionNumberScope;
