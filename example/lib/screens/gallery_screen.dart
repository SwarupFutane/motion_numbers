import 'package:flutter/material.dart';
import 'package:motion_number/motion_number.dart';

import '../tuning.dart';
import '../widgets/style_selector.dart';

/// One stop on the guided tour, and the thing it is there to demonstrate.
@immutable
class _TourStep {
  const _TourStep(this.value, this.note);

  final num value;
  final String note;
}

/// Job one: the style switcher, and a tour of the cases that are hard.
///
/// The tour is not a random walk. Each step is a transition that a naive
/// counter gets visibly wrong — a digit entering, a separator arriving, a
/// decrease — so stepping through it is an argument rather than a demo.
class GalleryScreen extends StatefulWidget {
  /// Creates the gallery.
  const GalleryScreen({
    required this.tuning,
    required this.onTuningChanged,
    super.key,
  });

  /// The tuning shared across the whole demo.
  final MotionTuning tuning;

  /// Called when the style chips change the selection.
  final ValueChanged<MotionTuning> onTuningChanged;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  static const List<_TourStep> _tour = <_TourStep>[
    _TourStep(1250, 'A starting balance. Nothing has moved yet.'),
    _TourStep(1310, 'Two digits roll; the rest hold still.'),
    _TourStep(9999, 'Still four digits.'),
    _TourStep(
      10000,
      'A digit enters. Alignment is right-anchored, so the row pushes open '
      'from the left instead of churning all four slots.',
    ),
    _TourStep(9999, 'And leaves again, closing the same way.'),
    _TourStep(124350, 'A jump wide enough that every slot has work to do.'),
    _TourStep(131890, 'Up. Watch which way the digits travel.'),
    _TourStep(124350, 'Down. The same slots, falling.'),
    _TourStep(999999, 'One comma.'),
    _TourStep(1000000, 'Two. Separators are slots too, so the comma slides.'),
    _TourStep(42, 'All the way back down.'),
  ];

  int _index = 0;

  _TourStep get _step => _tour[_index];

  void _go(int delta) => setState(() {
    _index = (_index + delta) % _tour.length;
    if (_index < 0) {
      _index += _tour.length;
    }
  });

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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: MotionNumberScope(
              child: Column(
                children: <Widget>[
                  FittedBox(
                    child: MotionNumber(
                      value: _step.value,
                      motion: tuning.motion,
                      duration: tuning.duration,
                      formatter: const PlainFormatter(prefix: '\u20b9'),
                      textStyle: theme.textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      directionColors: const DirectionColors.greenUp(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const MotionDelta(),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 56,
          child: Center(
            child: Text(
              _step.note,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: () => _go(-1),
              icon: const Icon(Icons.chevron_left),
              label: const Text('Back'),
            ),
            const SizedBox(width: 12),
            Text(
              '${_index + 1} / ${_tour.length}',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: () => _go(1),
              icon: const Icon(Icons.chevron_right),
              label: const Text('Next'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text('Style', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          styleBlurb(tuning.style),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        StyleSelector(
          value: tuning.style,
          onChanged: (NumberMotionStyle style) =>
              widget.onTuningChanged(tuning.withStyleDefaults(style)),
        ),
        const SizedBox(height: 32),
        Text('All seven, same value', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'One value change, seven strategies, one animation controller each. '
          'Stepping the tour above drives every row at once.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        for (final NumberMotionStyle style in NumberMotionStyle.values)
          _StyleRow(
            style: style,
            value: _step.value,
            selected: style == tuning.style,
            onTap: () =>
                widget.onTuningChanged(tuning.withStyleDefaults(style)),
          ),
      ],
    );
  }
}

/// One line of the comparison list: a style's name and that style animating.
class _StyleRow extends StatelessWidget {
  const _StyleRow({
    required this.style,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final NumberMotionStyle style;
  final num value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 104,
              child: Text(
                styleLabel(style),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected ? theme.colorScheme.primary : null,
                  fontWeight: selected ? FontWeight.w700 : null,
                ),
              ),
            ),
            const Spacer(),
            MotionNumber(
              value: value,
              style: style,
              textStyle: theme.textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}
