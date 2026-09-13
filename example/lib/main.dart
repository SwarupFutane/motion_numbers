import 'package:flutter/material.dart';
import 'package:motion_number/motion_number.dart';

import 'demo_shell.dart';
import 'screens/record_screen.dart';
import 'ticker.dart';

void main() => runApp(const MotionNumberDemo());

/// The example app for `motion_number`.
///
/// Three tabs — a style gallery, a live portfolio, and a parameter playground —
/// plus a chrome-free `/record/<style>` route that the README GIFs are captured
/// from.
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

  /// The app's motion language, set once.
  ///
  /// `MotionNumberTheme` is a `ThemeExtension`, so these are the defaults every
  /// call site inherits — the alternative being the same three arguments
  /// repeated at forty of them. An explicit argument on a widget still wins,
  /// which is what the screens rely on to override the style per tab.
  ThemeData _theme(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF3B5BDB),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      extensions: <ThemeExtension<dynamic>>[
        MotionNumberTheme(
          directionColors: const DirectionColors.greenUp(),
          deltaTextStyle: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'motion_number',
    debugShowCheckedModeBanner: false,
    theme: _theme(Brightness.light),
    darkTheme: _theme(Brightness.dark),
    home: DemoShell(ticker: _ticker),
    // `/record/<style>` and `/record/hero` are generated rather than listed,
    // so adding a style to the package adds its recording route for free.
    onGenerateRoute: (RouteSettings settings) {
      final RecordScreen? recorder = RecordScreen.fromRouteName(settings.name);
      if (recorder == null) {
        return null;
      }
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => recorder,
      );
    },
  );
}
