# Golden baselines

35 baselines: 7 motion styles x 5 time samples (`t = 0, .25, .5, .75, 1`).

## Record them on Linux, once

```bash
flutter test --tags golden --update-goldens
```

Font rasterisation differs between operating systems at the subpixel level. A
baseline recorded on Windows and compared on Linux CI fails by a handful of
antialiased pixels — permanently, meaninglessly, and unfixably, because
re-recording only moves the failure to the other platform. `ubuntu-latest` is
the one platform that records, which is why the whole group is skipped
elsewhere.

To look at the renders on another machine without committing them:

```bash
MOTION_NUMBER_GOLDENS=1 flutter test --tags golden --update-goldens
git clean -f test/golden/goldens        # then throw them away
```

## Why `--tags golden` exists

So a careless `flutter test --update-goldens` cannot silently overwrite every
baseline in the suite with whatever the local machine rendered today. To run
everything *except* the goldens: `flutter test -x golden`.

## The font

The frames load `roboto-regular.ttf` from `$FLUTTER_ROOT`. The default test
font draws every glyph as an identical filled box, which turns a digit strip
into a solid bar: without a real typeface all 35 baselines come out
byte-identical and the tier catches nothing. Borrowing the file from the SDK
keeps a 170 KB binary out of the published archive.

## What these are for

Catching visual regressions in the seven styles. *Not* for specifying
behaviour — that lives in the pure and widget tiers, which say what should
happen. A golden only says it still looks like it did last week.
