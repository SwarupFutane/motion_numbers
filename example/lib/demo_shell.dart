import 'package:flutter/material.dart';
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
  int _tab = 0;
  MotionTuning _tuning = MotionTuning.defaultsFor(NumberMotionStyle.rolling);

  void _setTuning(MotionTuning next) => setState(() => _tuning = next);

  Future<void> _openRecorder() async {
    final NumberMotionStyle? style = await showModalBottomSheet<
      NumberMotionStyle
    >(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const ListTile(
              title: Text('Record'),
              subtitle: Text(
                'Opens the chrome-free loop used for the README GIFs.',
              ),
            ),
            const Divider(height: 1),
            for (final NumberMotionStyle style in NumberMotionStyle.values)
              ListTile(
                title: Text(styleLabel(style)),
                subtitle: Text(recordRouteFor(style)),
                onTap: () => Navigator.of(context).pop(style),
              ),
          ],
        ),
      ),
    );
    if (style != null && mounted) {
      await Navigator.of(context).pushNamed(recordRouteFor(style));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('motion_number'),
      actions: <Widget>[
        IconButton(
          tooltip: 'Recording rig',
          icon: const Icon(Icons.radio_button_checked),
          onPressed: _openRecorder,
        ),
      ],
    ),
    body: switch (_tab) {
      0 => GalleryScreen(tuning: _tuning, onTuningChanged: _setTuning),
      1 => PortfolioScreen(ticker: widget.ticker, tuning: _tuning),
      _ => PlaygroundScreen(tuning: _tuning, onTuningChanged: _setTuning),
    },
    bottomNavigationBar: NavigationBar(
      selectedIndex: _tab,
      onDestinationSelected: (int index) => setState(() => _tab = index),
      destinations: const <NavigationDestination>[
        NavigationDestination(
          icon: Icon(Icons.auto_awesome_motion_outlined),
          selectedIcon: Icon(Icons.auto_awesome_motion),
          label: 'Gallery',
        ),
        NavigationDestination(
          icon: Icon(Icons.trending_up_outlined),
          selectedIcon: Icon(Icons.trending_up),
          label: 'Portfolio',
        ),
        NavigationDestination(
          icon: Icon(Icons.tune_outlined),
          selectedIcon: Icon(Icons.tune),
          label: 'Playground',
        ),
      ],
    ),
  );
}
