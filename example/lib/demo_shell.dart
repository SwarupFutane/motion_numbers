import 'package:flutter/cupertino.dart';
import 'package:motion_number/motion_number.dart';

import 'screens/gallery_screen.dart';
import 'screens/playground_screen.dart';
import 'screens/portfolio_screen.dart';
import 'ticker.dart';
import 'tuning.dart';

/// The three tabs, and the state they share.
///
/// Tuning lives here rather than in each screen so that a style picked in the
/// gallery is the style the portfolio ticks in and the playground generates
/// code for. Three screens that each remembered their own style would read as
/// three unrelated demos.
class DemoShell extends StatefulWidget {
  /// Creates the shell.
  const DemoShell({required this.ticker, super.key});

  /// The feed the portfolio tab renders.
  final PortfolioTicker ticker;

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  MotionTuning _tuning = MotionTuning.defaultsFor(NumberMotionStyle.rolling);

  void _setTuning(MotionTuning next) => setState(() => _tuning = next);

  @override
  Widget build(BuildContext context) => CupertinoTabScaffold(
    tabBar: CupertinoTabBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.sparkles),
          label: 'Gallery',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.chart_bar_alt_fill),
          label: 'Portfolio',
        ),
        BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.slider_horizontal_3),
          label: 'Playground',
        ),
      ],
    ),
    // No per-tab CupertinoTabView: a tab view captures its builder in the
    // first route it creates, so the shared tuning would stop reaching it.
    tabBuilder: (BuildContext context, int index) => switch (index) {
      0 => GalleryScreen(tuning: _tuning, onTuningChanged: _setTuning),
      1 => PortfolioScreen(ticker: widget.ticker, tuning: _tuning),
      _ => PlaygroundScreen(tuning: _tuning, onTuningChanged: _setTuning),
    },
  );
}
