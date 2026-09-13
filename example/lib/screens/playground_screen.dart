import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:motion_number/motion_number.dart';

import '../tuning.dart';
import '../widgets/labeled_slider.dart';
import '../widgets/style_selector.dart';

/// Job three: the parameters, as controls rather than as prose.
///
/// Duration and stagger are the two settings where the right value is taste,
/// not correctness. Documenting a taste question costs a paragraph nobody
/// believes; a slider settles it in thirty seconds. The generated snippet is
/// the point of the screen — you leave with the code, not with a feeling.
class PlaygroundScreen extends StatefulWidget {
  /// Creates the playground.
  const PlaygroundScreen({
    required this.tuning,
    required this.onTuningChanged,
    super.key,
  });

  /// The tuning shared across the whole demo.
  final MotionTuning tuning;

  /// Called whenever a control moves.
  final ValueChanged<MotionTuning> onTuningChanged;

  @override
  State<PlaygroundScreen> createState() => _PlaygroundScreenState();
}

class _PlaygroundScreenState extends State<PlaygroundScreen> {
  static const List<num> _values = <num>[124350, 131890, 129604, 130007];

  int _index = 0;
  Timer? _repeat;

  num get _value => _values[_index];

  void _advance() => setState(() => _index = (_index + 1) % _values.length);

  void _toggleRepeat() {
    setState(() {
      if (_repeat != null) {
        _repeat?.cancel();
        _repeat = null;
        return;
      }
      // Comfortably longer than the slowest transition, so a loop always
      // shows the settle rather than interrupting itself.
      _repeat = Timer.periodic(
        const Duration(milliseconds: 2600),
        (_) => _advance(),
      );
    });
  }

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MotionTuning tuning = widget.tuning;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: <Widget>[
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
            child: Center(
              child: FittedBox(
                child: MotionNumber(
                  value: _value,
                  motion: tuning.motion,
                  duration: tuning.duration,
                  textStyle: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FilledButton.icon(
              onPressed: _advance,
              icon: const Icon(Icons.refresh),
              label: const Text('Change the value'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _toggleRepeat,
              icon: Icon(_repeat != null ? Icons.stop : Icons.loop),
              label: Text(_repeat != null ? 'Stop looping' : 'Loop'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        StyleSelector(
          value: tuning.style,
          onChanged: (NumberMotionStyle style) =>
              widget.onTuningChanged(tuning.withStyleDefaults(style)),
        ),
        const SizedBox(height: 8),
        Text(
          styleBlurb(tuning.style),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        LabeledSlider(
          label: 'duration',
          readout: '${tuning.duration.inMilliseconds} ms',
          value: tuning.duration.inMilliseconds.toDouble(),
          min: 150,
          max: 2500,
          divisions: 47,
          onChanged: (double ms) => widget.onTuningChanged(
            tuning.copyWith(duration: Duration(milliseconds: ms.round())),
          ),
        ),
        LabeledSlider(
          label: 'staggerAmount',
          readout: tuning.stagger.toStringAsFixed(2),
          value: tuning.stagger,
          min: 0,
          max: MotionTuning.maxStagger,
          divisions: 19,
          disabledReason: 'odometer wheels share one shaft',
          onChanged: tuning.staggerApplies
              ? (double amount) =>
                    widget.onTuningChanged(tuning.copyWith(stagger: amount))
              : null,
        ),
        const SizedBox(height: 8),
        Text(
          'Stagger is what separates this from a tweened counter: it is the '
          'per-slot time offset that makes the digits arrive in sequence '
          'rather than together. Drag it to zero to see the difference.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 28),
        _Snippet(code: tuning.snippet),
      ],
    );
  }
}

/// The live code for the current tuning, ready to paste.
class _Snippet extends StatelessWidget {
  const _Snippet({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: SelectableText(
              code,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                height: 1.5,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(Icons.copy_all_outlined, size: 18),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: code));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
