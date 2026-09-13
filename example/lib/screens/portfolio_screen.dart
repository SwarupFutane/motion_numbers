import 'package:flutter/material.dart';
import 'package:motion_number/motion_number.dart';

import '../ticker.dart';
import '../tuning.dart';

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

  static const DirectionColors _colors = DirectionColors.greenUp();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return AnimatedBuilder(
      animation: ticker,
      builder: (BuildContext context, Widget? _) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: <Widget>[
          Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 28,
              ),
              child: MotionNumberScope(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Portfolio value',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FittedBox(
                      child: MotionNumber(
                        value: ticker.total,
                        motion: tuning.motion,
                        duration: tuning.duration,
                        formatter: const PlainFormatter(prefix: '\u20b9'),
                        textStyle: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        directionColors: _colors,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const MotionDelta(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: ticker.toggle,
                icon: Icon(
                  ticker.running ? Icons.pause : Icons.play_arrow,
                ),
                label: Text(ticker.running ? 'Pause feed' : 'Start feed'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: ticker.tick,
                icon: const Icon(Icons.skip_next),
                label: const Text('One tick'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: ticker.reset,
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Holdings', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final Holding holding in ticker.holdings)
            _HoldingRow(holding: holding, tuning: tuning),
        ],
      ),
    );
  }
}

/// One position: symbol, name, animated value, and its own delta.
class _HoldingRow extends StatelessWidget {
  const _HoldingRow({required this.holding, required this.tuning});

  final Holding holding;
  final MotionTuning tuning;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // A scope per row, so this row's delta reads this row's transition.
    return MotionNumberScope(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 64,
              child: Text(
                holding.symbol,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                holding.name,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                MotionNumber(
                  value: holding.value,
                  motion: tuning.motion,
                  duration: tuning.duration,
                  formatter: const PlainFormatter(prefix: '\u20b9'),
                  textStyle: theme.textTheme.titleMedium,
                  directionColors: PortfolioScreen._colors,
                ),
                const MotionDelta(
                  textStyle: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
