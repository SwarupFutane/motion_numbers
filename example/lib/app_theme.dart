import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:motion_number/motion_number.dart';

/// The demo's iOS look: system colours, SF Pro on Apple, Inter elsewhere.
///
/// SF Pro cannot be redistributed, but on iOS and macOS it is the system font
/// and Flutter reaches it through the `CupertinoSystem*` families. Everywhere
/// else the bundled Inter stands in — it was drawn for the same job and is the
/// closest open match in both metrics and tone.
abstract final class AppType {
  static bool get _isApple =>
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// The family for text below 20 pt.
  static String get textFamily => _isApple ? 'CupertinoSystemText' : 'Inter';

  /// The family for text at 20 pt and above.
  static String get displayFamily =>
      _isApple ? 'CupertinoSystemDisplay' : 'Inter';

  /// Tracking in points for [size].
  ///
  /// SF Pro ships with optical tracking baked into the system styles; Inter
  /// wants the same tightening at display sizes applied by hand, or large
  /// numbers read loose next to the native navigation bar.
  static double _tracking(double size) {
    if (_isApple) {
      return size >= 20 ? 0.35 : -0.4;
    }
    return size >= 20 ? -0.022 * size : -0.01 * size;
  }

  static TextStyle _style(
    double size,
    FontWeight weight, {
    Color color = CupertinoColors.label,
  }) => TextStyle(
    inherit: false,
    fontFamily: size >= 20 ? displayFamily : textFamily,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: _tracking(size),
    color: color,
    decoration: TextDecoration.none,
    textBaseline: TextBaseline.alphabetic,
  );

  /// 34 pt bold, the large navigation title.
  static TextStyle get largeTitle => _style(34, FontWeight.w700);

  /// 17 pt semibold, the collapsed navigation title and row titles.
  static TextStyle get headline => _style(17, FontWeight.w600);

  /// 17 pt regular, body copy.
  static TextStyle get body => _style(17, FontWeight.w400);

  /// 15 pt regular.
  static TextStyle get subheadline => _style(15, FontWeight.w400);

  /// 13 pt regular, section headers and footers.
  static TextStyle get footnote => _style(13, FontWeight.w400);

  /// 10 pt medium, tab bar labels.
  static TextStyle get tabLabel => _style(10, FontWeight.w500);

  /// A number at [size], semibold, with no tracking.
  ///
  /// Tracking is left at zero on purpose: `MotionNumber` gives every digit a
  /// fixed-width cell, and letter spacing would be added inside each one.
  static TextStyle number(double size, {FontWeight weight = FontWeight.w600}) =>
      _style(size, weight).copyWith(letterSpacing: 0);

  /// Monospaced, for the generated snippet.
  static TextStyle get code => const TextStyle(
    inherit: false,
    fontFamily: 'Menlo',
    fontFamilyFallback: <String>[
      'SF Mono',
      'Consolas',
      'Roboto Mono',
      'monospace',
    ],
    fontSize: 13,
    height: 1.5,
    color: CupertinoColors.label,
    decoration: TextDecoration.none,
  );

  /// The Cupertino theme built from these styles.
  static CupertinoThemeData theme() => CupertinoThemeData(
    primaryColor: CupertinoColors.systemBlue,
    scaffoldBackgroundColor: CupertinoColors.systemGroupedBackground,
    barBackgroundColor: CupertinoColors.systemGroupedBackground,
    textTheme: CupertinoTextThemeData(
      primaryColor: CupertinoColors.systemBlue,
      textStyle: body,
      actionTextStyle: body.copyWith(color: CupertinoColors.systemBlue),
      navTitleTextStyle: headline,
      navLargeTitleTextStyle: largeTitle,
      navActionTextStyle: body.copyWith(color: CupertinoColors.systemBlue),
      tabLabelTextStyle: tabLabel.copyWith(color: CupertinoColors.inactiveGray),
    ),
  );
}

/// Resolves a Cupertino dynamic colour for the current brightness.
///
/// Every colour in this demo is one of Apple's semantic colours, so light and
/// dark mode come for free — as long as nothing paints one unresolved.
Color resolveColor(Color color, BuildContext context) =>
    CupertinoDynamicColor.resolve(color, context);

/// iOS system green for up and red for down, resolved for [context].
DirectionColors iosDirectionColors(BuildContext context) => DirectionColors(
  up: resolveColor(CupertinoColors.systemGreen, context),
  down: resolveColor(CupertinoColors.systemRed, context),
);
