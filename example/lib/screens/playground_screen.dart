import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:motion_number/motion_number.dart';

import '../app_theme.dart';
import '../tuning.dart';
import '../widgets/ios.dart';
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
    final MotionTuning tuning = widget.tuning;
    final Color label = resolveColor(CupertinoColors.label, context);
    final Color secondary = resolveColor(
      CupertinoColors.secondaryLabel,
      context,
    );

    return IosPage(
      title: 'Playground',
      children: <Widget>[
        HeroCard(
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: MotionNumber(
                value: _value,
                motion: tuning.motion,
                duration: tuning.duration,
                textStyle: AppType.number(56).copyWith(color: label),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PillButton(
              label: 'Change value',
              icon: CupertinoIcons.arrow_2_circlepath,
              onPressed: _advance,
            ),
            const SizedBox(width: 10),
            PillButton(
              label: _repeat != null ? 'Stop' : 'Loop',
              icon: _repeat != null
                  ? CupertinoIcons.stop_fill
                  : CupertinoIcons.repeat,
              style: PillStyle.tinted,
              onPressed: _toggleRepeat,
            ),
          ],
        ),
        const SizedBox(height: 32),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 8),
          child: Text(
            'STYLE',
            style: AppType.footnote.copyWith(color: secondary),
          ),
        ),
        StyleSelector(
          value: tuning.style,
          onChanged: (NumberMotionStyle style) =>
              widget.onTuningChanged(tuning.withStyleDefaults(style)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 8, 32, 28),
          child: Text(
            styleBlurb(tuning.style),
            style: AppType.footnote.copyWith(color: secondary),
          ),
        ),
        IosSection(
          header: 'Timing',
          footer:
              'Stagger is the per-slot time offset that makes digits arrive in '
              'sequence rather than together. Drag it to zero to see the '
              'difference.',
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: <Widget>[
              SliderRow(
                label: 'Duration',
                readout: '${tuning.duration.inMilliseconds} ms',
                value: tuning.duration.inMilliseconds.toDouble(),
                min: 150,
                max: 2500,
                divisions: 47,
                onChanged: (double ms) => widget.onTuningChanged(
                  tuning.copyWith(duration: Duration(milliseconds: ms.round())),
                ),
              ),
              const IosDivider(),
              SliderRow(
                label: 'Stagger',
                readout: tuning.stagger.toStringAsFixed(2),
                value: tuning.stagger,
                min: 0,
                max: MotionTuning.maxStagger,
                divisions: 19,
                disabledReason: 'odometer wheels share one shaft',
                onChanged: tuning.staggerApplies
                    ? (double amount) => widget.onTuningChanged(
                        tuning.copyWith(stagger: amount),
                      )
                    : null,
              ),
            ],
          ),
        ),
        IosSection(
          header: 'Code',
          padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
          child: _Snippet(code: tuning.snippet),
        ),
      ],
    );
  }
}

/// The live code for the current tuning, ready to paste.
class _Snippet extends StatefulWidget {
  const _Snippet({required this.code});

  final String code;

  @override
  State<_Snippet> createState() => _SnippetState();
}

class _SnippetState extends State<_Snippet> {
  bool _copied = false;
  Timer? _reset;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) {
      return;
    }
    setState(() => _copied = true);
    _reset?.cancel();
    _reset = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() => _copied = false);
      }
    });
  }

  @override
  void dispose() {
    _reset?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(
            widget.code,
            style: AppType.code.copyWith(
              color: resolveColor(CupertinoColors.label, context),
            ),
          ),
        ),
      ),
      CupertinoButton(
        onPressed: _copy,
        padding: const EdgeInsets.all(8),
        minimumSize: const Size(44, 44),
        child: Icon(
          _copied ? CupertinoIcons.checkmark_alt : CupertinoIcons.doc_on_doc,
          size: 20,
          color: resolveColor(
            _copied ? CupertinoColors.systemGreen : CupertinoColors.systemBlue,
            context,
          ),
          semanticLabel: _copied ? 'Copied' : 'Copy',
        ),
      ),
    ],
  );
}
