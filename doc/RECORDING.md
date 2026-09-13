# Recording the README GIFs

The eight files listed in [`README.md`](README.md) are captured from the example
app's `/record/<style>` route. This page is the procedure; run it once the
styles are final, because re-recording eight loops after an easing curve moves
is exactly the tedium the phase ordering exists to avoid.

## What the route gives you

`example/lib/screens/record_screen.dart` renders one style, centred, with no app
bar and no navigation bar, looping `124,350 → 131,890 → 124,350` on a fixed
2200 ms beat. Everything about it is hard-coded rather than tunable: a rig whose
output depends on where a slider happened to be cannot reproduce the frame it
just replaced.

`/record/hero` is the variant for the above-the-fold shot — currency prefix,
larger type, `MotionDelta` beneath, direction colours on.

## Routes

| File to produce | Route |
|---|---|
| `hero.gif` | `/record/hero` |
| `rolling.gif` | `/record/rolling` |
| `odometer.gif` | `/record/odometer` |
| `slot_machine.gif` | `/record/slotMachine` |
| `flip.gif` | `/record/flip` |
| `wave.gif` | `/record/wave` |
| `shuffle.gif` | `/record/shuffle` |
| `elastic.gif` | `/record/elastic` |

Note `slotMachine` in the route but `slot_machine.gif` on disk: the route uses
the enum's own spelling, the filename follows the README's.

## 1 · Run it

```bash
cd example
flutter run -d chrome --release
```

Release matters. A debug build drops frames on the flip style's perspective
transform, and a recording of a debug build is a recording of the wrong thing.

Then navigate to the route, e.g. `http://localhost:<port>/#/record/flip`.

Desktop works too, and gives a steadier frame rate:

```bash
flutter run -d windows --release
```

There the recorder is reached through the ⏺ button in the app bar rather than
by URL.

## 2 · Capture

Capture the window region at **30 fps** for about **5 seconds** — two full
beats, so the loop shows both the rise and the fall. Crop to the number and its
label; leave the small close button in the top-left out of frame.

Any screen recorder that writes MP4 works. `ffmpeg` can grab the window
directly on Windows:

```bash
ffmpeg -f gdigrab -framerate 30 -t 5 -i title="motion_number" raw.mp4
```

## 3 · Convert

A two-pass palette is the difference between 300 KB and 3 MB. Do not skip it.

```bash
# One shared palette per clip, then apply it.
ffmpeg -i raw.mp4 -vf "fps=30,scale=640:-1:flags=lanczos,palettegen=stats_mode=diff" -y palette.png
ffmpeg -i raw.mp4 -i palette.png -lavfi "fps=30,scale=640:-1:flags=lanczos,paletteuse=dither=bayer:bayer_scale=3" -y ../doc/flip.gif
```

For `hero.gif` use `scale=800:-1`; it is the first impression and can afford
the extra width.

## 4 · Check the budget

**Under ~1 MB each.** The README loads on every package view, and a 6 MB hero is
the classic mistake.

```bash
ls -lh doc/*.gif
```

If one is over: drop the width to 480, or trim to a single beat. Lowering the
frame rate below 30 is the wrong lever — it is the smoothness of the digit
travel that the GIF exists to show.

## 5 · Verify the links

The README references these by **absolute** URL, because pub.dev does not
resolve relative paths:

```
https://raw.githubusercontent.com/SwarupFutane/motion_numbers/main/doc/<file>
```

The repository is `motion_numbers` (**plural**) while the package is
`motion_number` (singular). The images only resolve once the files are pushed to
`main` — checking them on a branch will show eight broken images and prove
nothing.
