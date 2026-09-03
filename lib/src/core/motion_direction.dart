/// The direction a numeric value moved during a transition.
///
/// Direction is the reason this package exists: a value that falls should
/// visibly fall. Motion styles read it to choose which way digits travel, and
/// [MotionDelta] reads it to choose an arrow and a colour.
enum MotionDirection {
  /// The new value is greater than the old value.
  up,

  /// The new value is less than the old value.
  down,

  /// The value did not change.
  none;

  /// Whether this direction is [MotionDirection.up].
  bool get isUp => this == MotionDirection.up;

  /// Whether this direction is [MotionDirection.down].
  bool get isDown => this == MotionDirection.down;

  /// Whether the value held still.
  bool get isNone => this == MotionDirection.none;

  /// The sign this direction contributes to motion.
  ///
  /// `1` for [up], `-1` for [down] and `0` for [none]. Motion styles multiply
  /// their translation by this so a decrease travels the opposite way.
  int get sign => switch (this) {
    MotionDirection.up => 1,
    MotionDirection.down => -1,
    MotionDirection.none => 0,
  };

  /// A word describing this direction, for screen readers.
  ///
  /// Screen readers do not reliably speak glyphs such as `↑`, so semantic
  /// labels use this instead.
  String get semanticLabel => switch (this) {
    MotionDirection.up => 'up',
    MotionDirection.down => 'down',
    MotionDirection.none => 'unchanged',
  };
}
