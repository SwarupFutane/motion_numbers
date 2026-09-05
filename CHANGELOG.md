# Changelog

## 0.1.0

Initial development release. The public API is not stable yet; treat every
`0.x` bump as potentially breaking.

### Widgets

* `MotionNumber` — a number whose digits animate independently when its value
  changes. Slots are right-anchored, so `999 → 1000` animates one new digit in
  rather than churning four, and separators animate rather than snap.
* `MotionDelta` — a direction-aware percentage or absolute delta, reading the
  nearest `MotionNumber`'s transition from an inherited scope or from an
  explicit `transition:`.
* `MotionNumberScope` — the `InheritedNotifier` the two communicate through.

### Motion

* Seven styles: `rolling`, `odometer`, `slotMachine`, `flip`, `wave`,
  `shuffle`, `elastic`.
* `DigitMotion` is the open strategy contract behind them — pass `motion:` to
  supply your own without touching the widget layer.

### Formatting

* `PlainFormatter`, `IntlFormatter` (any `intl` `NumberFormat`, including
  `en_IN` lakh/crore grouping) and `CompactFormatter` (`1.2M` / `12.4L`).
* `NumberTextFormatter` is the extension point for anything else.

### Theming and accessibility

* `MotionNumberTheme` as a `ThemeExtension`, plus `DirectionColors` with
  `greenUp()` and `redUp()` presets.
* The formatted value is announced to screen readers; the `0`–`9` strips are
  excluded from semantics.
* `MediaQuery.disableAnimationsOf` short-circuits every slot to its final
  position on the first frame.
