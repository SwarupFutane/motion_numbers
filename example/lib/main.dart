import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Theme, ThemeData, ThemeExtension;
import 'package:motion_number/motion_number.dart';

import 'app_theme.dart';
import 'demo_shell.dart';
import 'ticker.dart';

void main() => runApp(const MotionNumberDemo());

/// The example app for `motion_number`.
///
/// Three tabs — a style gallery, a live portfolio, and a parameter playground —
/// in an iOS shell.
class MotionNumberDemo extends StatefulWidget {
  /// Creates the demo app.
  const MotionNumberDemo({super.key});

  @override
  State<MotionNumberDemo> createState() => _MotionNumberDemoState();
}

class _MotionNumberDemoState extends State<MotionNumberDemo> {
  final PortfolioTicker _ticker = PortfolioTicker();

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CupertinoApp(
    title: 'motion_number',
    debugShowCheckedModeBanner: false,
    theme: AppType.theme(),
    builder: (BuildContext context, Widget? child) => Theme(
      // `MotionNumberTheme` is a `ThemeExtension`, so it has to ride on a
      // Material `Theme` even in an app that is otherwise all Cupertino. These
      // are the defaults every call site inherits; an explicit argument on a
      // widget still wins.
      //
      // `Theme` also installs a `CupertinoTheme` derived from itself, which
      // would replace the one `CupertinoApp` just set up — hence the override.
      data: ThemeData(
        brightness: MediaQuery.platformBrightnessOf(context),
        fontFamily: AppType.textFamily,
        cupertinoOverrideTheme: AppType.theme(),
        extensions: <ThemeExtension<dynamic>>[
          MotionNumberTheme(
            directionColors: iosDirectionColors(context),
            deltaTextStyle: AppType.subheadline.copyWith(
              fontWeight: FontWeight.w600,
              color: resolveColor(CupertinoColors.secondaryLabel, context),
            ),
          ),
        ],
      ),
      child: child!,
    ),
    home: DemoShell(ticker: _ticker),
  );
}
