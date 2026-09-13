import 'package:flutter/cupertino.dart';
import 'package:motion_number/motion_number.dart';

import '../app_theme.dart';
import '../ticker.dart';
import '../tuning.dart';
import '../widgets/ios.dart';

/// Job two: a live feed, where the direction colours and `MotionDelta` earn
/// their place.
///
/// One detail worth copying: **every row has its own [MotionNumberScope]**.
/// A `MotionNumber` publishes into the nearest ancestor scope, so four numbers
/// under one scope would all overwrite the same transition and every delta on
/// the screen would show whichever row ticked last.
class PortfolioScreen extends StatelessWidget {
  /// Creates the portfolio screen.
  const PortfolioScreen({
    required this.ticker,
    required this.tuning,
    super.key,
  });

  /// The feed driving the numbers.
  final PortfolioTicker ticker;

  /// The tuning shared across the whole demo.
  final MotionTuning tuning;

  @override
  Widget build(BuildContext context) {
    final Color label = resolveColor(CupertinoColors.label, context);
    final Color secondary = resolveColor(
      CupertinoColors.secondaryLabel,
      context,
    );

    return AnimatedBuilder(
      animation: ticker,
      builder: (BuildContext context, Widget? _) => IosPage(
        title: 'Portfolio',
        children: <Widget>[
          HeroCard(
            child: MotionNumberScope(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Portfolio value',
                    style: AppType.subheadline.copyWith(color: secondary),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: MotionNumber(
                      value: ticker.total,
                      motion: tuning.motion,
                      duration: tuning.duration,
                      formatter: const PlainFormatter(prefix: '₹'),
                      textStyle: AppType.number(48).copyWith(color: label),
                      directionColors: iosDirectionColors(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const MotionDelta(),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                PillButton(
                  label: ticker.running ? 'Pause feed' : 'Start feed',
                  icon: ticker.running
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  onPressed: ticker.toggle,
                ),
                PillButton(
                  label: 'Tick',
                  icon: CupertinoIcons.forward_end_fill,
                  style: PillStyle.tinted,
                  onPressed: ticker.tick,
                ),
                PillButton(
                  label: 'Reset',
                  style: PillStyle.plain,
                  onPressed: ticker.reset,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          IosSection(
            header: 'Holdings',
            padding: EdgeInsets.zero,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < ticker.holdings.length; i++) ...<Widget>[
                  if (i > 0) const IosDivider(indent: 70),
                  _HoldingRow(holding: ticker.holdings[i], tuning: tuning),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One position: badge, symbol and name, animated value, and its own delta.
class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.holding, required this.tuning});

  final Holding holding;
  final MotionTuning tuning;

  static const List<Color> _badgeColors = <Color>[
    CupertinoColors.systemIndigo,
    CupertinoColors.systemOrange,
    CupertinoColors.systemTeal,
    CupertinoColors.systemPink,
    CupertinoColors.systemPurple,
  ];

  @override
  Widget build(BuildContext context) {
    final Color label = resolveColor(CupertinoColors.label, context);
    final Color secondary = resolveColor(
      CupertinoColors.secondaryLabel,
      context,
    );
    final Color badge = resolveColor(
      _badgeColors[holding.symbol.codeUnitAt(0) % _badgeColors.length],
      context,
    );

    // A scope per row, so this row's delta reads this row's transition.
    return MotionNumberScope(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: badge,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                holding.symbol.substring(0, 1),
                style: AppType.headline.copyWith(color: CupertinoColors.white),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    holding.symbol,
                    style: AppType.headline.copyWith(color: label),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    holding.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.footnote.copyWith(color: secondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                MotionNumber(
                  value: holding.value,
                  motion: tuning.motion,
                  duration: tuning.duration,
                  formatter: const PlainFormatter(prefix: '₹'),
                  textStyle: AppType.number(
                    17,
                    weight: FontWeight.w500,
                  ).copyWith(color: label),
                  directionColors: iosDirectionColors(context),
                ),
                const SizedBox(height: 2),
                MotionDelta(
                  textStyle: AppType.footnote.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
