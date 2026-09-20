@Tags(<String>['golden'])
library;

import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:motion_number/src/motion/number_motion_style.dart';
import 'package:motion_number/src/widgets/motion_number.dart';

/// Whether pixel baselines are meaningful on the machine running the suite.
///
/// Font rasterisation differs between operating systems at the subpixel level,
/// so a baseline recorded on one and compared on another fails permanently and
/// for no real reason. Linux is the canonical platform because that is what CI
/// runs; set `MOTION_NUMBER_GOLDENS=1` to look at the renders elsewhere, but
/// never commit what that produces.
final bool _thisPlatformRecords =
    Platform.isLinux || Platform.environment['MOTION_NUMBER_GOLDENS'] == '1';

/// Roboto, borrowed from the Flutter SDK rather than vendored into the repo.
///
/// The default test font draws every glyph as an identical filled box, which
/// makes a digit strip a solid bar: all seven styles at all five samples come
/// out byte-identical and the tier catches nothing. Real digit outlines are
/// what makes a golden a golden. Borrowing the SDK's copy keeps a 170 KB
/// binary out of the published archive.
final File? _roboto = _findRoboto();

/// The SDK's `roboto-regular.ttf`, or `null` if no candidate path has it.
///
/// `FLUTTER_ROOT` alone is not enough: it is unset in some runners and points
/// at the outer checkout in the monorepo layout, where the SDK sits one level
/// down in `src/flutter`. The test binary itself is the reliable anchor —
/// `flutter_tester` lives in `bin/cache/artifacts/engine/<platform>/`, so the
/// fonts are two directories up from the engine folder.
List<String> _candidates = <String>[];

File? _findRoboto() {
  const String leaf = 'material_fonts/roboto-regular.ttf';
  final String? root = Platform.environment['FLUTTER_ROOT'];
  _candidates = <String>[
    if (root != null) '$root/bin/cache/artifacts/$leaf',
    if (root != null) '$root/src/flutter/bin/cache/artifacts/$leaf',
  ];

  Directory dir = File(Platform.resolvedExecutable).parent;
  while (dir.path != dir.parent.path) {
    if (dir.path.endsWith('artifacts') || dir.path.endsWith('cache')) {
      _candidates.add('${dir.path}/$leaf');
      _candidates.add('${dir.path}/artifacts/$leaf');
    }
    dir = dir.parent;
  }

  for (final String path in _candidates) {
    final File file = File(path);
    if (file.existsSync()) {
      return file;
    }
  }
  return null;
}

/// Why the golden tier is not running, or `null` when it is.
String? get _skip {
  if (!_thisPlatformRecords) {
    return 'baselines are recorded on Linux only';
  }
  if (_roboto == null) {
    return 'roboto-regular.ttf not found in ${_candidates.join(', ')} '
        '(FLUTTER_ROOT=${Platform.environment['FLUTTER_ROOT']}, '
        'executable=${Platform.resolvedExecutable}) — run `flutter precache`';
  }
  return null;
}

/// A round duration so the samples land on exact controller values.
const Duration _duration = Duration(milliseconds: 1000);

/// `t = 0, .25, .5, .75, 1` — the start, three points mid-flight, and the rest.
const List<int> _samples = <int>[0, 25, 50, 75, 100];

/// The transition every style is photographed making.
///
/// Four digits that all change, so the stagger is visible across the row, plus
/// a grouping separator that must stay put while they move.
const int _from = 1234;
const int _to = 5678;

/// The frame every baseline is shot in: fixed size, white, one style.
Widget _frame(num value, NumberMotionStyle style) => MediaQuery(
  data: const MediaQueryData(),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 32,
        color: Color(0xFF101010),
      ),
      child: RepaintBoundary(
        key: const ValueKey<String>('golden-frame'),
        child: ColoredBox(
          color: const Color(0xFFFFFFFF),
          child: SizedBox(
            width: 280,
            height: 96,
            child: Center(
              child: MotionNumber(
                value: value,
                style: style,
                duration: _duration,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(() async {
    if (_skip != null) {
      return;
    }
    final Uint8List bytes = _roboto!.readAsBytesSync();
    await (FontLoader(
      'Roboto',
    )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
  });

  for (final NumberMotionStyle style in NumberMotionStyle.values) {
    group('${style.name} renders', () {
      for (final int percent in _samples) {
        final String label = (percent / 100).toStringAsFixed(2);

        testWidgets('at t = $label', (WidgetTester tester) async {
          tester.view.physicalSize = const Size(280, 96);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          // Settled on the old value: animateOnFirstBuild is off by default.
          await tester.pumpWidget(_frame(_from, style));

          // The new value starts the transition; this frame is t = 0.
          await tester.pumpWidget(_frame(_to, style));
          if (percent > 0) {
            await tester.pump(_duration * (percent / 100));
          }

          await expectLater(
            find.byKey(const ValueKey<String>('golden-frame')),
            matchesGoldenFile('goldens/${style.name}_t$percent.png'),
          );

          await tester.pumpAndSettle();
        });
      }
    }, skip: _skip);
  }
}
