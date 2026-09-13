import 'package:flutter/material.dart';

/// A slider with its name, its current value, and a reason when it is off.
///
/// The disabled case matters: `odometer` takes no stagger, and a control that
/// silently does nothing teaches the reader that the parameter is broken rather
/// than that the style does not have one.
class LabeledSlider extends StatelessWidget {
  /// Creates a labelled slider.
  const LabeledSlider({
    required this.label,
    required this.readout,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.disabledReason,
    super.key,
  });

  /// The control's name.
  final String label;

  /// The formatted current value, shown beside [label].
  final String readout;

  /// The current value.
  final double value;

  /// The lowest selectable value.
  final double min;

  /// The highest selectable value.
  final double max;

  /// How many discrete steps the slider snaps to, or `null` for continuous.
  final int? divisions;

  /// Called as the slider moves. `null` disables the control.
  final ValueChanged<double>? onChanged;

  /// Shown in place of the value when the slider is disabled.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool enabled = onChanged != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: enabled ? null : theme.disabledColor,
              ),
            ),
            const Spacer(),
            Text(
              enabled ? readout : (disabledReason ?? 'not applicable'),
              style: theme.textTheme.labelMedium?.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                color: enabled
                    ? theme.colorScheme.primary
                    : theme.disabledColor,
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
