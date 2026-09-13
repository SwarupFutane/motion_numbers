import 'package:flutter/material.dart';
import 'package:motion_number/motion_number.dart';

import '../tuning.dart';

/// A chip per [NumberMotionStyle], which is the whole style switcher.
class StyleSelector extends StatelessWidget {
  /// Creates a selector.
  const StyleSelector({
    required this.value,
    required this.onChanged,
    this.alignment = WrapAlignment.start,
    super.key,
  });

  /// The currently selected style.
  final NumberMotionStyle value;

  /// Called with the newly selected style.
  final ValueChanged<NumberMotionStyle> onChanged;

  /// How the chips are distributed along each line.
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: alignment,
    children: <Widget>[
      for (final NumberMotionStyle style in NumberMotionStyle.values)
        ChoiceChip(
          label: Text(styleLabel(style)),
          selected: style == value,
          onSelected: (_) => onChanged(style),
        ),
    ],
  );
}
