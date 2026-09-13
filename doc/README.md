# doc/ — README media

The eight files the README links to. **None of them exist yet.** The rig that
produces them does: Phase 7 built the example app's `/record/<style>` route, and
[`RECORDING.md`](RECORDING.md) is the step-by-step. Until the files are captured
and pushed to `main`, the images in the README render as broken links on GitHub
and pub.dev.

| File | Route | Shows |
|---|---|---|
| `hero.gif` | `/record/hero` | Above the fold. A currency value rolling, with the delta beside it. |
| `rolling.gif` | `/record/rolling` | One short loop per style — |
| `odometer.gif` | `/record/odometer` | short enough to read at a glance, |
| `slot_machine.gif` | `/record/slotMachine` | long enough to show the settle. |
| `flip.gif` | `/record/flip` | |
| `wave.gif` | `/record/wave` | |
| `shuffle.gif` | `/record/shuffle` | |
| `elastic.gif` | `/record/elastic` | |

## Rules

- **Under ~1 MB each.** The README loads on every package view, and `hero.gif`
  is the first impression. A 6 MB hero is the classic mistake here.
- **Linked by absolute URL**, already written that way in the README:
  `https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/<file>`.
  pub.dev does not resolve relative paths — a relative link renders on GitHub
  and breaks on the package page, which is the one place it matters.
- The repository is `motion_numbers` (**plural**) while the package is
  `motion_number` (singular). The URLs must match the remote that resolves,
  not the package name.
- Record at 30 fps from the example app on web or desktop.

Record these *after* the styles are final. Re-recording eight loops because one
easing curve moved is exactly the tedium this ordering avoids.

`doc/api/` is gitignored — that is dartdoc's output, not media.
