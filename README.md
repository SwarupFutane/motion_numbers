# motion_number

Numeric data that **arrives** instead of appearing. Every digit animates on its
own timeline, the motion knows whether the value rose or fell, and seven distinct
styles share one engine.

<!--
GIFs go here, above the fold, once the example app exists (Phase 7).
pub.dev does NOT resolve relative paths — use absolute URLs, one per style:
![rolling](https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/rolling.gif)
Keep each under ~1 MB; this README loads on every package view.
-->

> **Status: `0.1.0`, pre-1.0.** The API may still move. Everything below is
> covered by tests, but pin an exact version if you need stability today.

---

## Why not just tween a double?

Most animated counters interpolate a `double` and re-render `value.toString()`
each frame. That produces three visible defects:

| Defect | Cause | What you see |
|---|---|---|
| Layout jitter | Proportional fonts make `1` and `8` different widths | The row twitches every frame |
| Meaningless motion | The *string* is interpolated, not the digits | `₹9,999 → ₹10,000` scrambles all five glyphs |
| No direction | A number is just a number | Nothing tells you it went **up** |

`motion_number` treats a formatted number as a stable list of **glyph slots**.
Alignment is right-anchored, so `999 → 1000` rolls three digits and enters one —
it does not churn all four. Separators are slots too, so grouping changes animate
instead of snapping.

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
MotionNumber(value: 131890)
```

That is the whole API for the common case. The value is formatted with grouped
thousands, each digit rolls the shortest way to its target, and the row keeps a
fixed width throughout.

---

## The example this package exists for

Indian lakh–crore grouping and a direction-aware delta, together:

```dart
MotionNumberScope(
  child: Column(
    children: <Widget>[
      MotionNumber(
        value: portfolio,                       // 124350 → 131890
        formatter: IntlFormatter.currency(
          locale: 'en_IN',
          symbol: '₹',
          decimalDigits: 0,
        ),
        style: NumberMotionStyle.rolling,
        directionColors: const DirectionColors.greenUp(),
      ),
      const MotionDelta(),                      // ↑ +6.06%
    ],
  ),
)
```

`₹1,24,350 → ₹1,31,890` — note the grouping is `1,24,350`, not `124,350`. Only
one comma moves, the rupee sign never flickers, and `MotionDelta` renders
`↑ +6.06%` in green.

`MotionDelta` is a sibling widget rather than a parameter, so it can sit anywhere
in your layout. It reads the nearest `MotionNumberScope`; wrap the region that
needs to see the change, or pass `transition:` explicitly and skip the scope.

---

## The seven styles

All seven share the same cached digit strip and the same clip. They differ only
in **path**, **easing** and **stagger** — which is why one engine hosts them all.

| Style | Path through digits | Default duration | Curve | Feel |
|---|---|---|---|---|
| `rolling` | Shortest path; ties broken by direction | 650 ms | `easeOutCubic` | Clean, financial |
| `odometer` | Always continuous, carries `9 → 0` | 800 ms | `easeInOutCubic` | Physical dial |
| `slotMachine` | 2–4 extra revolutions before settling | 1400 ms | `decelerate` | Casino reveal |
| `flip` | Split-flap: two half clips, X-axis rotation | 700 ms | `easeInOut` | Airport board |
| `wave` | Rolling plus a sinusoidal lift across the row | 900 ms | `easeOutSine` | Playful, organic |
| `shuffle` | Scrambles, then settles | 1100 ms | `easeOutQuart` | Decrypting |
| `elastic` | Rolling with overshoot and a scale pop | 1000 ms | `elasticOut` | Bouncy, gamified |

**Direction awareness lives here.** A decrease visibly *falls*: `rolling`, `wave`
and `elastic` reverse their translation, `odometer` reverses its carry, and
`flip` folds the other way.

Not enough? Implement `DigitMotion` and pass `motion:` — the enum is sugar, not a
ceiling.

```dart
MotionNumber(value: v, motion: const SlotMachineMotion(minRevolutions: 3))
```

---

## Formatting

Three formatters ship; `intl` is the only runtime dependency and `PlainFormatter`
never touches it.

```dart
const PlainFormatter()                               // 124,350
const PlainFormatter(decimalDigits: 2, prefix: r'$') // $124,350.00
IntlFormatter.decimal(locale: 'en_IN')               // 1,24,350
IntlFormatter.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0)
const CompactFormatter()                            // 1.2M
const CompactFormatter(scale: CompactScale.indian)  // 12.4L
```

Implement `NumberTextFormatter` for anything else — it returns a `String`, so
there is nothing else to satisfy.

---

## Parameters

### `MotionNumber`

| Parameter | Type | Default | Purpose |
|---|---|---|---|
| `value` | `num` | required | The value to display |
| `style` | `NumberMotionStyle` | `rolling` | Which built-in style to use |
| `motion` | `DigitMotion?` | `null` | A custom strategy; overrides `style` |
| `formatter` | `NumberTextFormatter?` | `PlainFormatter()` | How the value becomes text |
| `duration` | `Duration?` | style default | Transition length |
| `curve` | `Curve?` | style default | Easing |
| `textStyle` | `TextStyle?` | ambient | Digit text style |
| `tabularFigures` | `bool` | `true` | Request fixed-advance figures |
| `animateOnFirstBuild` | `bool` | `false` | Animate on mount |
| `directionColors` | `DirectionColors?` | `null` | Tint digits by direction |
| `onTransition` | `ValueChanged<ValueTransition>?` | `null` | Called when a transition starts |

### `MotionDelta`

| Parameter | Type | Default | Purpose |
|---|---|---|---|
| `transition` | `ValueTransition?` | nearest scope | What to render |
| `decimalDigits` | `int` | `2` | Precision of the percentage |
| `showArrow` | `bool` | `true` | Prefix `↑` / `↓` |
| `textStyle` | `TextStyle?` | theme, then ambient | Text style |
| `directionColors` | `DirectionColors?` | theme | Colour by direction |
| `deltaBuilder` | `Widget Function(BuildContext, ValueTransition)?` | `null` | Replace the default rendering |

---

## Theming

Set the motion language once instead of at forty call sites:

```dart
ThemeData(
  extensions: <ThemeExtension<dynamic>>[
    const MotionNumberTheme(
      style: NumberMotionStyle.odometer,
      duration: Duration(milliseconds: 900),
      directionColors: DirectionColors.greenUp(),
    ),
  ],
)
```

Resolution order is **explicit argument → theme → the style's own default**, so a
single widget can always opt out.

Red-for-up is the convention in several markets, so it is not hard-coded:
`DirectionColors.redUp()` swaps the pair.

---

## Accessibility

Not an afterthought — it is why the widget layer is more than a `Row`.

- The widget announces the **formatted number**, once, as a live region.
- The `0`–`9` strips are wrapped in `ExcludeSemantics`. Without this a screen
  reader recites "zero one two three four five six seven eight nine" for every
  digit on screen.
- `MediaQuery.disableAnimationsOf` short-circuits to the final frame: correct
  value, no motion.
- `MotionDelta` speaks direction as a **word** — "up 6.06 percent" — because `↑`
  is not reliably spoken.

---

## Performance

| Concern | Mitigation |
|---|---|
| N controllers | **One** controller per widget; independence comes from stagger |
| Rebuilding 10 `Text`s per digit per frame | Strips built once in `State` and reused |
| Row-wide repaint | `RepaintBoundary` per digit cell |
| `TextPainter` cost | Digit metrics measured once per `TextStyle`, cached library-wide |

A twelve-digit `MotionNumber` costs one ticker, not twelve.

**Interruption is handled.** If the value changes mid-flight, the widget
snapshots the digits currently on screen, diffs from *those*, and restarts —
so a live ticker never visibly rewinds.

---

## Additional information

- **Issues and feature requests:**
  [github.com/SwarupFutane/motion_numbers/issues](https://github.com/SwarupFutane/motion_numbers/issues)
- **Source:**
  [github.com/SwarupFutane/motion_numbers](https://github.com/SwarupFutane/motion_numbers)
- **Not in 1.0, deliberately:** chart integration, server-driven motion config,
  per-digit independent colours, and locale auto-detection. Each is a decision,
  not an oversight — `IntlFormatter` already accepts any `NumberFormat`.

Everything under `lib/src/` is private. `package:motion_number/motion_number.dart`
is the entire public surface, which is what keeps the semver contract small.

## License

MIT — see [LICENSE](LICENSE).
