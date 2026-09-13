# doc/ — README media

The seven animated WebP files the README links to, one short loop per style.
They are captured by hand from the example app; until they are pushed to
`main`, the images in the README render as broken links on GitHub and pub.dev.

| File | Style |
|---|---|
| `rolling.webp` | `NumberMotionStyle.rolling` |
| `odometer.webp` | `NumberMotionStyle.odometer` |
| `slot_machine.webp` | `NumberMotionStyle.slotMachine` |
| `flip.webp` | `NumberMotionStyle.flip` |
| `wave.webp` | `NumberMotionStyle.wave` |
| `shuffle.webp` | `NumberMotionStyle.shuffle` |
| `elastic.webp` | `NumberMotionStyle.elastic` |

## Rules

- **Animated WebP, not GIF.** GIF stores frame delays in hundredths of a
  second, so 60 fps is impossible and fast frames get clamped by browsers. WebP
  stores milliseconds, keeps full colour, and is typically 2–3× smaller.
- **Under ~1 MB each.** The README loads on every package view. Trim to one
  up-and-down loop or reduce the width before lowering the frame rate.
- **Linked by absolute URL**, already written that way in the README:
  `https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/<file>`.
  pub.dev does not resolve relative paths — a relative link renders on GitHub
  and breaks on the package page, which is the one place it matters.
- The repository is `motion_numbers` (**plural**) while the package is
  `motion_number` (singular). The URLs must match the remote that resolves,
  not the package name.

`doc/api/` is gitignored — that is dartdoc's output, not media.
