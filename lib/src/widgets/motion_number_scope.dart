import 'package:flutter/widgets.dart';

import '../core/value_transition.dart';

/// Shares the most recent [ValueTransition] with a subtree.
///
/// `MotionNumber` publishes every transition it runs into the nearest ancestor
/// scope, and `MotionDelta` reads it back. Wrap whatever region needs to see
/// the change:
///
/// ```dart
/// MotionNumberScope(
///   child: Column(
///     children: <Widget>[
///       MotionNumber(value: portfolio),
///       MotionDelta(),
///     ],
///   ),
/// )
/// ```
///
/// The scope is required because `MotionDelta` is a *sibling* of the number,
/// not a descendant — an inherited widget placed inside `MotionNumber` could
/// never be seen from outside it.
class MotionNumberScope extends StatefulWidget {
  /// Creates a scope around [child].
  const MotionNumberScope({required this.child, super.key});

  /// The subtree that can read transitions published into this scope.
  final Widget child;

  /// The latest transition, or `null` if there is no scope or nothing has been
  /// published yet.
  ///
  /// Depending on this rebuilds the caller whenever a new transition arrives.
  static ValueTransition? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_MotionNumberScopeMarker>()
      ?.notifier
      ?.value;

  /// The latest transition, asserting that a scope is present.
  static ValueTransition of(BuildContext context) {
    final ValueTransition? transition = maybeOf(context);
    assert(
      transition != null,
      'No MotionNumberScope found above this widget, or nothing has been '
      'published into it yet. Wrap the region in a MotionNumberScope, or pass '
      'an explicit transition.',
    );
    return transition!;
  }

  /// Publishes [transition] into the nearest ancestor scope, if there is one.
  ///
  /// Returns whether a scope was found. Safe to call when none exists — a
  /// `MotionNumber` used on its own simply has nowhere to publish.
  static bool publish(BuildContext context, ValueTransition transition) {
    final _MotionNumberScopeState? state = context
        .findAncestorStateOfType<_MotionNumberScopeState>();
    if (state == null) {
      return false;
    }
    state.publish(transition);
    return true;
  }

  @override
  State<MotionNumberScope> createState() => _MotionNumberScopeState();
}

class _MotionNumberScopeState extends State<MotionNumberScope> {
  final ValueNotifier<ValueTransition?> _transition =
      ValueNotifier<ValueTransition?>(null);

  void publish(ValueTransition transition) => _transition.value = transition;

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      _MotionNumberScopeMarker(notifier: _transition, child: widget.child);
}

/// The inherited half of [MotionNumberScope].
class _MotionNumberScopeMarker
    extends InheritedNotifier<ValueNotifier<ValueTransition?>> {
  const _MotionNumberScopeMarker({
    required super.notifier,
    required super.child,
  });
}
