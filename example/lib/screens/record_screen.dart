import 'dart:async';

import 'package:flutter/material.dart';
import 'package:motion_number/motion_number.dart';

import '../tuning.dart';

/// The GIF rig: one style, no chrome, looping on a fixed cadence.
///
/// Reachable at `/record/<style>` — so on web the capture is scriptable by URL
/// (`#/record/flip`) rather than by clicking through the app first. The eight
/// files in `doc/` are recorded from here; see `doc/RECORDING.md`.
///
/// Everything on this screen is deliberately fixed rather than tunable. A
/// recording rig whose output depends on where a slider happened to be is a rig
/// that cannot reproduce the frame it just replaced.
class RecordScreen extends StatefulWidget {
  /// Creates the recording surface for [style].
  const RecordScreen({required this.style, this.hero = false, super.key});

  /// The style being recorded.
  final NumberMotionStyle style;

  /// Whether to record the hero shot: currency, delta, larger type.
  final bool hero;

  /// The route this screen is mounted at, or `null` if [name] is not one.
  ///
  /// `/record/hero` is the README's above-the-fold shot; `/record/<style>` is
  /// one of the seven per-style loops.
  static RecordScreen? fromRouteName(String? name) {
    if (name == null || !name.startsWith('/record/')) {
      return null;
    }
    final String slug = name.substring('/record/'.length);
    if (slug == 'hero') {
      return const RecordScreen(style: NumberMotionStyle.rolling, hero: true);
    }
    for (final NumberMotionStyle style in NumberMotionStyle.values) {
      if (styleLabel(style) == slug) {
        return RecordScreen(style: style);
      }
    }
    return null;
  }

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen> {
  /// The loop. Up, then back down, so a single pass shows both directions —
  /// which is the whole claim the package makes.
  static const List<num> _loop = <num>[124350, 131890];

  /// Long enough for the slowest style (shuffle, 1100 ms) to settle and be
  /// read before the next change.
  static const Duration _beat = Duration(milliseconds: 2200);

  int _index = 0;
  Timer? _timer;

  num get _value => _loop[_index];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      _beat,
      (_) => setState(() => _index = (_index + 1) % _loop.length),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle? numberStyle =
        (widget.hero
                ? theme.textTheme.displayLarge
                : theme.textTheme.displayMedium)
            ?.copyWith(fontWeight: FontWeight.w600);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: <Widget>[
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: MotionNumberScope(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    FittedBox(
                      child: MotionNumber(
                        value: _value,
                        style: widget.style,
                        formatter: widget.hero
                            ? const PlainFormatter(prefix: '\u20b9')
                            : const PlainFormatter(),
                        textStyle: numberStyle,
                        directionColors: widget.hero
                            ? const DirectionColors.greenUp()
                            : null,
                      ),
                    ),
                    if (widget.hero) ...<Widget>[
                      const SizedBox(height: 12),
                      const MotionDelta(
                        textStyle: TextStyle(fontSize: 24),
                        directionColors: DirectionColors.greenUp(),
                      ),
                    ] else ...<Widget>[
                      const SizedBox(height: 16),
                      Text(
                        styleLabel(widget.style),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          // Small and out of the crop, so it does not land in the GIF.
          Positioned(
            left: 4,
            top: 4,
            child: IconButton(
              tooltip: 'Back',
              iconSize: 18,
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }
}
