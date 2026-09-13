# motion_number — example

The showcase app. Three tabs and one shared tuning, in an iOS-style shell —
large titles, inset-grouped sections, system colours, SF Pro on Apple platforms
and the bundled Inter everywhere else.

```bash
cd example
flutter run          # or: flutter run -d chrome
```

| Tab | What it is for |
|---|---|
| **Gallery** | The style switcher, and a guided tour of the transitions a naive counter gets wrong — a digit entering, a separator arriving, a decrease. All seven styles animate the same value side by side. |
| **Portfolio** | A live feed. `MotionDelta` going green and red, direction colours, four holdings each with their own scope. |
| **Playground** | Duration and stagger as sliders, with the Dart for the current settings generated live below them. |

## The thing worth reading the source for

`staggerAmount` is a **constructor argument on each motion style**, not a
parameter of `MotionNumber`. So a UI that tunes stagger has to build the
strategy itself:

```dart
MotionNumber(
  value: value,
  motion: RollingMotion(staggerAmount: 0.4),   // not `style:`
)
```

[`lib/tuning.dart`](lib/tuning.dart) is the only file in the example that names
a concrete style class; every screen goes through it. `OdometerMotion` takes no
stagger at all — its wheels sit on one shaft — which is why the playground
disables that slider and says so rather than leaving a control that does
nothing.

The other detail worth copying is in
[`lib/screens/portfolio_screen.dart`](lib/screens/portfolio_screen.dart): every
holding row gets **its own `MotionNumberScope`**. A `MotionNumber` publishes
into the nearest ancestor scope, so four numbers under one scope would all
overwrite the same transition and every delta on screen would show whichever
row ticked last.

## Tests

```bash
flutter test
```

Widget smoke tests for the three tabs plus unit tests for the tuning and the
ticker. The visual regressions are the package's problem, not the example's —
the goldens live in `../test/golden/`.
