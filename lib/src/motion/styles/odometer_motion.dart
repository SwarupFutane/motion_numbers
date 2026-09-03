import 'package:flutter/widgets.dart';

import '../digit_motion.dart';
import '../slot_render_data.dart';

/// A mechanical dial: digits always travel continuously, never by shortcut.
///
/// Where `rolling` takes the shortest path, an odometer carries. `1 → 9` on a
/// rising value climbs the whole way through `2…8` rather than dropping two
/// steps, because a physical dial cannot do otherwise. There is no stagger:
/// the wheels are on one shaft.
class OdometerMotion extends DigitMotion {
  /// Creates an odometer motion.
  const OdometerMotion();

  @override
  Duration get defaultDuration => const Duration(milliseconds: 800);

  @override
  Curve get defaultCurve => Curves.easeInOutCubic;

  /// The path this style takes, which is not the shortest one.
  double _distance(SlotRenderData data) => DigitMotion.continuousDistance(
    data.fromDigit!,
    data.toDigit!,
    data.direction,
  );

  @override
  Widget buildSlot(BuildContext context, SlotRenderData data, double t) =>
      Transform.translate(
        offset: Offset(
          0,
          -DigitMotion.stripPosition(data.fromDigit!, _distance(data), t) *
              data.cellHeight,
        ),
        child: data.strip,
      );

  @override
  int visibleDigit(SlotRenderData data, double t) =>
      DigitMotion.stripPosition(data.fromDigit!, _distance(data), t).round() %
      10;
}
