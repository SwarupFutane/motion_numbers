import 'package:flutter/cupertino.dart';

import '../app_theme.dart';

/// A large-title page: the navigation bar collapses as the content scrolls.
class IosPage extends StatelessWidget {
  /// Creates a page titled [title] with [children] stacked beneath.
  const IosPage({required this.title, required this.children, super.key});

  /// The large title, also the collapsed title.
  final String title;

  /// The page content, top to bottom.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => CupertinoPageScaffold(
    child: CustomScrollView(
      slivers: <Widget>[
        CupertinoSliverNavigationBar(
          largeTitle: Text(title),
          border: null,
          backgroundColor: resolveColor(
            CupertinoColors.systemGroupedBackground,
            context,
          ).withValues(alpha: 0.92),
        ),
        SliverSafeArea(
          top: false,
          sliver: SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 32),
            sliver: SliverList.list(children: children),
          ),
        ),
      ],
    ),
  );
}

/// An inset-grouped section: an optional uppercase header, a rounded card,
/// and an optional footer — the shape of every iOS Settings screen.
class IosSection extends StatelessWidget {
  /// Creates a section around [child].
  const IosSection({
    required this.child,
    this.header,
    this.footer,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  /// Shown above the card in small caps.
  final String? header;

  /// Shown below the card in secondary text.
  final String? footer;

  /// Inside the card.
  final EdgeInsetsGeometry padding;

  /// The card's content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Color secondary = resolveColor(
      CupertinoColors.secondaryLabel,
      context,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 7),
              child: Text(
                header!.toUpperCase(),
                style: AppType.footnote.copyWith(color: secondary),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: resolveColor(
                CupertinoColors.secondarySystemGroupedBackground,
                context,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(padding: padding, child: child),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
              child: Text(
                footer!,
                style: AppType.footnote.copyWith(color: secondary),
              ),
            ),
        ],
      ),
    );
  }
}

/// A hairline between rows, inset from the leading edge like UITableView.
class IosDivider extends StatelessWidget {
  /// Creates a divider inset by [indent].
  const IosDivider({this.indent = 16, super.key});

  /// Leading inset.
  final double indent;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(start: indent),
    child: Container(
      height: 0.5,
      color: resolveColor(CupertinoColors.separator, context),
    ),
  );
}

/// How strongly a [PillButton] is drawn.
enum PillStyle {
  /// Solid tint, white label: the primary action.
  filled,

  /// Pale tint, tinted label: a secondary action.
  tinted,

  /// Label only.
  plain,
}

/// A capsule button in the iOS 15+ `UIButton.Configuration` style.
class PillButton extends StatelessWidget {
  /// Creates a button.
  const PillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = PillStyle.filled,
    this.color = CupertinoColors.systemBlue,
    super.key,
  });

  /// The label.
  final String label;

  /// An optional leading SF Symbol-style icon.
  final IconData? icon;

  /// Called on tap. `null` disables the button.
  final VoidCallback? onPressed;

  /// Filled, tinted or plain.
  final PillStyle style;

  /// The tint.
  final Color color;

  @override
  Widget build(BuildContext context) {
    final Color tint = resolveColor(color, context);
    final Color foreground = switch (style) {
      PillStyle.filled => CupertinoColors.white,
      PillStyle.tinted || PillStyle.plain => tint,
    };
    final Color? background = switch (style) {
      PillStyle.filled => tint,
      PillStyle.tinted => tint.withValues(alpha: 0.15),
      PillStyle.plain => null,
    };

    return CupertinoButton(
      onPressed: onPressed,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      borderRadius: BorderRadius.circular(100),
      color: background,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppType.headline.copyWith(color: foreground, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// A row with a title, a trailing readout and a slider beneath.
class SliderRow extends StatelessWidget {
  /// Creates a slider row.
  const SliderRow({
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

  /// The formatted current value.
  final String readout;

  /// The current value.
  final double value;

  /// Lowest value.
  final double min;

  /// Highest value.
  final double max;

  /// Snap steps, or `null` for continuous.
  final int? divisions;

  /// Called as the slider moves. `null` disables it.
  final ValueChanged<double>? onChanged;

  /// Shown instead of [readout] while disabled.
  ///
  /// `odometer` takes no stagger, and a control that silently does nothing
  /// teaches the reader the parameter is broken rather than absent.
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;
    final Color secondary = resolveColor(
      CupertinoColors.secondaryLabel,
      context,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                label,
                style: AppType.body.copyWith(
                  color: enabled
                      ? resolveColor(CupertinoColors.label, context)
                      : resolveColor(CupertinoColors.tertiaryLabel, context),
                ),
              ),
              const Spacer(),
              Flexible(
                child: Text(
                  enabled ? readout : (disabledReason ?? 'Not applicable'),
                  textAlign: TextAlign.end,
                  style: AppType.body.copyWith(
                    color: secondary,
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            width: double.infinity,
            child: CupertinoSlider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

/// A card that holds the hero number on each screen.
class HeroCard extends StatelessWidget {
  /// Creates the card.
  const HeroCard({required this.child, super.key});

  /// The number and anything beneath it.
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: resolveColor(
          CupertinoColors.secondarySystemGroupedBackground,
          context,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: child,
      ),
    ),
  );
}
