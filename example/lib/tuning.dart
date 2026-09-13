import 'package:flutter/material.dart';
import 'package:motion_number/motion_number.dart';

/// The three knobs this demo exposes, and the [DigitMotion] they add up to.
///
/// The interesting asymmetry in `motion_number`'s API lives here: `duration` is
/// an argument to `MotionNumber`, but **stagger is not** — it is a constructor
/// argument on each style. So a UI that wants to tune stagger has to build the
/// strategy itself and pass it through `motion:`. This class is the only place
/// in the example that names a concrete style class; every screen talks to it.
@immutable
class MotionTuning {
  /// Creates a tuning from explicit values.
  const MotionTuning({
    required this.style,
    required this.duration,
    required this.stagger,
  });

  /// The tuning a style ships with, straight from the package's own defaults.
  factory MotionTuning.defaultsFor(NumberMotionStyle style) => MotionTuning(
    style: style,
    duration: resolveMotionStyle(style).defaultDuration,
    stagger: defaultStaggerFor(style),
  );

  /// The largest stagger the styles accept: `staggerAmount` asserts `[0, 1)`.
  static const double maxStagger = 0.95;

  /// Which style is selected.
  final NumberMotionStyle style;

  /// How long one transition takes.
  final Duration duration;

  /// The fraction of the timeline spread across the slots.
  final double stagger;

  /// Whether [stagger] changes anything for [style].
  ///
  /// It does not for `odometer`, and that is a design decision rather than a
  /// gap: an odometer's wheels sit on one shaft, so they cannot lag each other.
  bool get staggerApplies => style != NumberMotionStyle.odometer;

  /// The strategy these settings describe.
  DigitMotion get motion => switch (style) {
    NumberMotionStyle.rolling => RollingMotion(staggerAmount: stagger),
    NumberMotionStyle.odometer => const OdometerMotion(),
    NumberMotionStyle.slotMachine => SlotMachineMotion(staggerAmount: stagger),
    NumberMotionStyle.flip => FlipMotion(staggerAmount: stagger),
    NumberMotionStyle.wave => WaveMotion(staggerAmount: stagger),
    NumberMotionStyle.shuffle => ShuffleMotion(staggerAmount: stagger),
    NumberMotionStyle.elastic => ElasticMotion(staggerAmount: stagger),
  };

  /// The Dart that reproduces this tuning, shown live in the playground.
  ///
  /// A demo that lets you tune something and then makes you guess the code for
  /// it has only done half the job.
  String get snippet {
    final String buildStagger = staggerApplies
        ? '(staggerAmount: ${stagger.toStringAsFixed(2)})'
        : '()';
    return 'MotionNumber(\n'
        '  value: value,\n'
        '  motion: const ${_className(style)}$buildStagger,\n'
        '  duration: const Duration(milliseconds: ${duration.inMilliseconds}),\n'
        ')';
  }

  /// A copy with individual fields replaced.
  MotionTuning copyWith({
    NumberMotionStyle? style,
    Duration? duration,
    double? stagger,
  }) => MotionTuning(
    style: style ?? this.style,
    duration: duration ?? this.duration,
    stagger: stagger ?? this.stagger,
  );

  /// The same tuning with [style] selected and that style's own defaults.
  MotionTuning withStyleDefaults(NumberMotionStyle next) =>
      MotionTuning.defaultsFor(next);

  /// The `staggerAmount` the given style is constructed with by default.
  static double defaultStaggerFor(NumberMotionStyle style) => switch (style) {
    NumberMotionStyle.rolling => const RollingMotion().staggerAmount,
    NumberMotionStyle.odometer => 0,
    NumberMotionStyle.slotMachine => const SlotMachineMotion().staggerAmount,
    NumberMotionStyle.flip => const FlipMotion().staggerAmount,
    NumberMotionStyle.wave => const WaveMotion().staggerAmount,
    NumberMotionStyle.shuffle => const ShuffleMotion().staggerAmount,
    NumberMotionStyle.elastic => const ElasticMotion().staggerAmount,
  };

  static String _className(NumberMotionStyle style) => switch (style) {
    NumberMotionStyle.rolling => 'RollingMotion',
    NumberMotionStyle.odometer => 'OdometerMotion',
    NumberMotionStyle.slotMachine => 'SlotMachineMotion',
    NumberMotionStyle.flip => 'FlipMotion',
    NumberMotionStyle.wave => 'WaveMotion',
    NumberMotionStyle.shuffle => 'ShuffleMotion',
    NumberMotionStyle.elastic => 'ElasticMotion',
  };
}

/// The label shown on chips and headings for [style].
String styleLabel(NumberMotionStyle style) => switch (style) {
  NumberMotionStyle.rolling => 'rolling',
  NumberMotionStyle.odometer => 'odometer',
  NumberMotionStyle.slotMachine => 'slotMachine',
  NumberMotionStyle.flip => 'flip',
  NumberMotionStyle.wave => 'wave',
  NumberMotionStyle.shuffle => 'shuffle',
  NumberMotionStyle.elastic => 'elastic',
};

/// The one-line description of what [style] feels like.
String styleBlurb(NumberMotionStyle style) => switch (style) {
  NumberMotionStyle.rolling => 'Shortest path, direction-aware. The default.',
  NumberMotionStyle.odometer => 'A mechanical dial, always continuous.',
  NumberMotionStyle.slotMachine => 'Extra revolutions, staggered hard.',
  NumberMotionStyle.flip => 'Split-flap board: fold away, fall in.',
  NumberMotionStyle.wave => 'Rolling with a sinusoidal offset across the row.',
  NumberMotionStyle.shuffle => 'Scrambles, then settles. The decrypting look.',
  NumberMotionStyle.elastic => 'Rolling with overshoot and a scale pop.',
};

/// The route name that records [style] as a README GIF.
String recordRouteFor(NumberMotionStyle style) =>
    '/record/${styleLabel(style)}';
