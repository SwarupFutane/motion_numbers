import 'package:flutter/cupertino.dart';
import 'package:motion_number/motion_number.dart';

import '../app_theme.dart';
import '../tuning.dart';

/// A horizontally scrolling row of capsules, one per [NumberMotionStyle].
///
/// Seven options is too many for a segmented control at phone width, so this
/// follows the filter-pill pattern from Apple's own apps instead.
class StyleSelector extends StatelessWidget {
  /// Creates a selector.
  const StyleSelector({
    required this.value,
    required this.onChanged,
    super.key,
  });

  /// The currently selected style.
  final NumberMotionStyle value;

  /// Called with the newly selected style.
  final ValueChanged<NumberMotionStyle> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: <Widget>[
        for (final NumberMotionStyle style in NumberMotionStyle.values)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: StylePill(
              label: styleLabel(style),
              selected: style == value,
              onTap: () => onChanged(style),
            ),
          ),
      ],
    ),
  );
}

/// One capsule in a [StyleSelector].
class StylePill extends StatelessWidget {
  /// Creates a pill.
  const StylePill({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  /// The style's name.
  final String label;

  /// Whether this is the current style.
  final bool selected;

  /// Called on tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color blue = resolveColor(CupertinoColors.systemBlue, context);
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? blue
                : resolveColor(CupertinoColors.tertiarySystemFill, context),
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: AppType.subheadline.copyWith(
              fontWeight: FontWeight.w600,
              color: selected
                  ? CupertinoColors.white
                  : resolveColor(CupertinoColors.label, context),
            ),
          ),
        ),
      ),
    );
  }
}
