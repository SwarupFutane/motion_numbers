# motion_number

Numbers that **arrive** instead of appearing. Every digit rolls on its own
timeline, the motion knows whether the value went up or down, and seven styles
share one animation controller.

<!-- HERO GIF — recorded in Phase 7 from the example app. Absolute URL, because
     pub.dev does not resolve relative paths. -->
![motion_number rolling a currency value](https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/hero.gif)

```dart
MotionNumber(value: 131890)
```

That is the whole API for the common case. Everything below is opt-in.

---

## Why not just tween a double?

Most animated counters interpolate a `double` and re-render `value.toString()`
every frame. Three things go wrong:

| Defect | Cause | What you see |
|---|---|---|
| Layout jitter | Proportional fonts give `1` and `8` different widths | The row twitches every frame |
| Meaningless motion | The *string* is interpolated, not the digits | `₹9,999 → ₹10,000` scrambles all five glyphs |
| No direction | A number is just a number | Nothing says it went **up** |

`motion_number` treats a formatted number as a stable list of glyph slots.
Slots are aligned from the right, so `999 → 1000` animates **one** new digit in
rather than churning four. Separators are slots too, so a new comma slides in
instead of snapping.

---

## The seven styles

<!-- One short loop per style, recorded in Phase 7. Keep each under ~1 MB: the
     README loads on every package view. -->

| rolling | odometer | slotMachine |
|---|---|---|
| ![rolling](https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/rolling.gif) | ![odometer](https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/odometer.gif) | ![slot machine](https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/slot_machine.gif) |
| Shortest path, direction-aware. Clean and financial. The default. | A mechanical dial, always continuous, carrying `9 → 0`. | Extra revolutions before settling, staggered hard. |

| flip | wave | shuffle |
|---|---|---|
| ![flip](https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/flip.gif) | ![wave](https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/wave.gif) | ![shuffle](https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/shuffle.gif) |
| Split-flap board: the old digit folds away, the new one falls in. | Rolling with a sinusoidal offset across the row. | Random digits, then a settle. The "decrypting" look. |

| elastic |
|---|
| ![elastic](https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/elastic.gif) |
| Rolling with overshoot and a small scale pop. |

```dart
MotionNumber(value: 131890, style: NumberMotionStyle.flip)
```

---

## Install

```yaml
dependencies:
  motion_number: ^0.1.0
```

```dart
import 'package:motion_number/motion_number.dart';
```

---

## Minimal example

```dart
int _value = 1234;

MotionNumber(value: _value)
```

Change `_value` inside `setState` and it animates. No controller to own, no
`dispose` to remember.

---

## Indian currency, with a direction-aware delta

`₹1,24,350 → ₹1,31,890`, and the percentage that goes with it:

```dart
Row(
  children: <Widget>[
    MotionNumber(
      value: amount,
      formatter: IntlFormatter.currency(
        locale: 'en_IN',
        symbol: '₹',
        decimalDigits: 0,
      ),
      directionColors: const DirectionColors.greenUp(),
    ),
    const SizedBox(width: 8),
    const MotionDelta(),
  ],
)
```

`MotionDelta` renders `↑ +6.06%` with no wiring between the two widgets:
`MotionNumber` publishes each transition into an inherited scope, and any
`MotionDelta` below it reads from there. Pass `transition:` explicitly if you
would rather not use the scope.

Two things here that a fixed-width grouper cannot do: `en_IN` groups the leading
digits in pairs (`1,24,350`, not `124,350`), and the delta knows the value rose.
Percentage change from zero is undefined, so a transition starting at `0` shows
the absolute delta instead of `∞%` or a silently wrong `100%`.

---

## Formatters

| Formatter | Input | Output |
|---|---|---|
| `PlainFormatter()` | `131890` | `131,890` |
| `PlainFormatter(grouped: false)` | `131890` | `131890` |
| `IntlFormatter.decimal(locale: 'en_IN')` | `124350` | `1,24,350` |
| `IntlFormatter.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)` | `124350` | `₹1,24,350` |
| `CompactFormatter()` | `1243500` | `1.2M` |
| `CompactFormatter(scale: CompactScale.indian)` | `1243500` | `12.4L` |

`IntlFormatter` wraps any `intl` `NumberFormat`, which is why locale
auto-detection and currency conversion stay out of scope — pass whichever format
you want. Implement `NumberTextFormatter` for anything else.

---

## Parameters

### `MotionNumber`

| Parameter | Type | Default | What it does |
|---|---|---|---|
| `value` | `num` | required | The value to display |
| `style` | `NumberMotionStyle` | `rolling` | Which built-in motion to use |
| `motion` | `DigitMotion?` | `null` | A custom strategy, overriding `style` |
| `formatter` | `NumberTextFormatter?` | `PlainFormatter()` | How the value becomes text |
| `duration` | `Duration?` | the style's own | How long a transition takes |
| `curve` | `Curve?` | the style's own | Easing applied to the transition |
| `textStyle` | `TextStyle?` | ambient | Style for the digits |
| `tabularFigures` | `bool` | `true` | Requests `tnum`, making digit widths exact |
| `animateOnFirstBuild` | `bool` | `false` | Whether the first build animates from zero |
| `directionColors` | `DirectionColors?` | `null` | Tints digits by direction while they move |
| `onTransition` | `ValueChanged<ValueTransition>?` | `null` | Fires when a transition begins |

`animateOnFirstBuild` is off by default so that opening a dashboard does not
animate every number on it at once.

### `MotionDelta`

| Parameter | Type | Default | What it does |
|---|---|---|---|
| `transition` | `ValueTransition?` | nearest scope's | Which transition to render |
| `decimalDigits` | `int` | `2` | Digits after the decimal point |
| `showArrow` | `bool` | `true` | Whether to prefix `↑` / `↓` |
| `textStyle` | `TextStyle?` | theme, then ambient | Style for the text |
| `directionColors` | `DirectionColors?` | theme's | Colours applied by direction |
| `deltaBuilder` | `Widget Function(BuildContext, ValueTransition)?` | `null` | Replaces the default rendering entirely |

---

## Theming

`MotionNumberTheme` is a `ThemeExtension`, so defaults live with the rest of
your theme rather than at every call site:

```dart
MaterialApp(
  theme: ThemeData(
    extensions: const <ThemeExtension<dynamic>>[
      MotionNumberTheme(
        style: NumberMotionStyle.odometer,
        duration: Duration(milliseconds: 700),
        directionColors: DirectionColors.greenUp(),
      ),
    ],
  ),
)
```

Resolution order is explicit argument, then theme, then the style's own default.
`DirectionColors.redUp()` is there for markets where red means a rise.

---

## Accessibility

A screen reader announces the formatted value — `131,890` — and nothing else.
The `0`–`9` strip that each digit slides through is wrapped in
`ExcludeSemantics`; without that, every digit would read out as "zero one two
three four five six seven eight nine".

`MediaQuery.disableAnimationsOf` is honoured: when a user has asked their
platform to reduce motion, every slot renders at `t = 1.0` on the first frame.
The value is correct immediately, and nothing moves.

---

## Performance

One `AnimationController` drives the whole widget however many digits it has —
per-digit independence comes from stagger, not from twelve tickers. The `0`–`9`
strip is built once and reused until the text style or cell size changes, each
digit sits behind a `RepaintBoundary`, and cell width is measured from the widest
glyph so the row never reflows mid-animation.

---

## Status

`0.x`, and the constraint above should be read that way: the API is not frozen,
and the parameter tables may still change before `1.0.0`. Behaviour is covered
by 155 tests, plus a golden suite over all seven styles.

Issues and pull requests:
[SwarupFutane/motion_numbers](https://github.com/SwarupFutane/motion_numbers).

## License

MIT — see
[LICENSE](https://github.com/SwarupFutane/motion_numbers/blob/main/LICENSE).
