import 'motion_direction.dart';

/// An immutable description of one value change.
///
/// This is the single source of truth for "what just happened" to a number.
/// `MotionNumber` builds one on every value change and publishes it through
/// `MotionNumberScope`; `MotionDelta` reads it to render `↑ +6.05%`.
///
/// It is a plain value object with no Flutter dependency, so direction and
/// percentage arithmetic is unit-testable without pumping a widget.
class ValueTransition {
  /// Creates a transition from already-computed parts.
  ///
  /// Prefer [ValueTransition.between], which derives [delta], [percentChange]
  /// and [direction] consistently.
  const ValueTransition({
    required this.from,
    required this.to,
    required this.delta,
    required this.percentChange,
    required this.direction,
    this.isFirstBuild = false,
  });

  /// Derives a transition from an old and a new value.
  ///
  /// [percentChange] is `null` when [from] is zero, because percentage change
  /// from zero is undefined — not infinite, and not 100%.
  ///
  /// Throws an [ArgumentError] if either value is NaN or infinite; such a value
  /// cannot be formatted into digits, so failing here beats failing mid-frame.
  factory ValueTransition.between(
    num from,
    num to, {
    bool isFirstBuild = false,
  }) {
    _checkFinite(from, 'from');
    _checkFinite(to, 'to');

    final num delta = to - from;
    return ValueTransition(
      from: from,
      to: to,
      delta: delta,
      percentChange: _percentChange(from, delta),
      direction: _directionOf(delta),
      isFirstBuild: isFirstBuild,
    );
  }

  /// A still transition for a widget's very first build.
  ///
  /// [from] and [to] are both [value], so nothing animates unless the caller
  /// has opted into `animateOnFirstBuild`.
  factory ValueTransition.initial(num value) {
    _checkFinite(value, 'value');
    return ValueTransition(
      from: value,
      to: value,
      delta: 0,
      percentChange: null,
      direction: MotionDirection.none,
      isFirstBuild: true,
    );
  }

  /// The value before the change.
  final num from;

  /// The value after the change.
  final num to;

  /// [to] minus [from].
  final num delta;

  /// The signed percentage change, or `null` when [from] is zero.
  ///
  /// Computed against the *magnitude* of [from], so the sign always follows
  /// [delta]: `-100 → -50` is `+50%`, an increase.
  final double? percentChange;

  /// Which way the value moved.
  final MotionDirection direction;

  /// Whether this transition represents a widget's first build.
  ///
  /// Motion is suppressed on the first build unless explicitly enabled, so a
  /// screen does not animate every number from zero when it opens.
  final bool isFirstBuild;

  /// Whether the value actually changed.
  bool get hasChanged => delta != 0;

  /// Returns a copy with the given fields replaced.
  ValueTransition copyWith({bool? isFirstBuild}) => ValueTransition(
    from: from,
    to: to,
    delta: delta,
    percentChange: percentChange,
    direction: direction,
    isFirstBuild: isFirstBuild ?? this.isFirstBuild,
  );

  static void _checkFinite(num value, String name) {
    if (value is double && !value.isFinite) {
      throw ArgumentError.value(value, name, 'must be finite');
    }
  }

  static MotionDirection _directionOf(num delta) {
    if (delta > 0) {
      return MotionDirection.up;
    }
    if (delta < 0) {
      return MotionDirection.down;
    }
    return MotionDirection.none;
  }

  static double? _percentChange(num from, num delta) {
    if (from == 0) {
      return null;
    }
    return delta / from.abs() * 100;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueTransition &&
          other.from == from &&
          other.to == to &&
          other.delta == delta &&
          other.percentChange == percentChange &&
          other.direction == direction &&
          other.isFirstBuild == isFirstBuild;

  @override
  int get hashCode =>
      Object.hash(from, to, delta, percentChange, direction, isFirstBuild);

  @override
  String toString() =>
      'ValueTransition($from → $to, delta: $delta, '
      'percent: $percentChange, direction: ${direction.name})';
}
