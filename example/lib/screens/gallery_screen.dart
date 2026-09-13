import 'package:flutter/cupertino.dart';
import 'package:motion_number/motion_number.dart';

import '../app_theme.dart';
import '../tuning.dart';
import '../widgets/ios.dart';

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

  /// Called when a style row is tapped.
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
    final MotionTuning tuning = widget.tuning;
    final Color label = resolveColor(CupertinoColors.label, context);
    final Color secondary = resolveColor(
      CupertinoColors.secondaryLabel,
      context,
    );

    return IosPage(
      title: 'Gallery',
      children: <Widget>[
        HeroCard(
          child: MotionNumberScope(
            child: Column(
              children: <Widget>[
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: MotionNumber(
                    value: _step.value,
                    motion: tuning.motion,
                    duration: tuning.duration,
                    formatter: const PlainFormatter(prefix: '₹'),
                    textStyle: AppType.number(56).copyWith(color: label),
                    directionColors: iosDirectionColors(context),
                  ),
                ),
                const SizedBox(height: 8),
                const MotionDelta(),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            height: 64,
            child: Center(
              child: Text(
                _step.note,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: AppType.subheadline.copyWith(color: secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            PillButton(
              label: 'Back',
              icon: CupertinoIcons.chevron_left,
              style: PillStyle.tinted,
              onPressed: () => _go(-1),
            ),
            const SizedBox(width: 16),
            Text(
              '${_index + 1} / ${_tour.length}',
              style: AppType.subheadline.copyWith(
                color: secondary,
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 16),
            PillButton(
              label: 'Next',
              icon: CupertinoIcons.chevron_right,
              onPressed: () => _go(1),
            ),
          ],
        ),
        const SizedBox(height: 32),
        IosSection(
          header: 'Styles',
          footer:
              '${styleBlurb(tuning.style)} Every row animates the same value, '
              'so stepping the tour drives all seven at once.',
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              for (final NumberMotionStyle style
                  in NumberMotionStyle.values) ...<Widget>[
                if (style != NumberMotionStyle.values.first) const IosDivider(),
                _StyleRow(
                  style: style,
                  value: _step.value,
                  selected: style == tuning.style,
                  onTap: () =>
                      widget.onTuningChanged(tuning.withStyleDefaults(style)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One row of the style list: name, that style animating, and a checkmark.
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
    final Color label = resolveColor(CupertinoColors.label, context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 11, 12, 11),
          child: Row(
            children: <Widget>[
              Text(
                styleLabel(style),
                style: AppType.body.copyWith(color: label),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: MotionNumber(
                      value: value,
                      style: style,
                      textStyle: AppType.number(
                        20,
                        weight: FontWeight.w500,
                      ).copyWith(color: label),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                child: selected
                    ? Icon(
                        CupertinoIcons.checkmark_alt,
                        size: 22,
                        color: resolveColor(
                          CupertinoColors.systemBlue,
                          context,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
