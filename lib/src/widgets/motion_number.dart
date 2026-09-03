import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../core/digit_metrics.dart';
import '../core/glyph.dart';
import '../core/glyph_differ.dart';
import '../core/motion_direction.dart';
import '../core/value_transition.dart';
import '../formatting/number_text_formatter.dart';
import '../formatting/plain_formatter.dart';
import '../motion/digit_motion.dart';
import '../motion/number_motion_style.dart';
import '../motion/slot_render_data.dart';
import '../theme/direction_colors.dart';
import 'digit_cell.dart';
import 'motion_number_scope.dart';
import 'separator_cell.dart';

/// A number whose digits animate independently when its value changes.
///
/// Each digit is a slot on its own timeline, aligned right so that
/// `999 → 1000` enters one new digit instead of churning all four. Separators
/// are slots too, so grouping changes animate rather than snap.
///
/// ```dart
/// MotionNumber(value: 131890)
/// ```
///
/// One [AnimationController] drives every slot; per-digit independence comes
/// from stagger, so a twelve-digit number costs one ticker, not twelve.
class MotionNumber extends StatefulWidget {
  /// Creates an animated number.
  const MotionNumber({
    required this.value,
    this.style = NumberMotionStyle.rolling,
    this.motion,
    this.formatter,
    this.duration,
    this.curve,
    this.textStyle,
    this.tabularFigures = true,
    this.animateOnFirstBuild = false,
    this.directionColors,
    this.onTransition,
    super.key,
  });

  /// The value to display.
  final num value;

  /// Which built-in motion style to use. Ignored when [motion] is supplied.
  final NumberMotionStyle style;

  /// A custom motion strategy, overriding [style].
  final DigitMotion? motion;

  /// How [value] is turned into text. Defaults to a grouped [PlainFormatter].
  final NumberTextFormatter? formatter;

  /// How long a transition takes. Defaults to the style's own duration.
  final Duration? duration;

  /// The easing applied to the transition. Defaults to the style's own curve.
  final Curve? curve;

  /// The text style for the digits. Defaults to the ambient [DefaultTextStyle].
  final TextStyle? textStyle;

  /// Whether to request tabular figures, making digit widths exact.
  final bool tabularFigures;

  /// Whether to animate on the widget's first build.
  ///
  /// Off by default, so opening a screen does not animate every number from
  /// zero at once.
  final bool animateOnFirstBuild;

  /// Tints the digits by direction while they move.
  final DirectionColors? directionColors;

  /// Called whenever a transition begins.
  final ValueChanged<ValueTransition>? onTransition;

  @override
  State<MotionNumber> createState() => _MotionNumberState();
}

class _MotionNumberState extends State<MotionNumber>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late ValueTransition _transition;

  /// The glyphs currently being animated away from, and towards.
  List<GlyphSpec> _fromGlyphs = const <GlyphSpec>[];
  List<GlyphSpec> _toGlyphs = const <GlyphSpec>[];
  List<SlotInstruction> _instructions = const <SlotInstruction>[];

  /// Cached digit strip, rebuilt only when the style or metrics change.
  Widget? _strip;
  TextStyle? _stripStyle;
  Size? _stripCell;
  int? _stripRepeats;

  NumberTextFormatter get _formatter =>
      widget.formatter ?? const PlainFormatter();

  DigitMotion get _motion => widget.motion ?? resolveMotionStyle(widget.style);

  Duration get _duration => widget.duration ?? _motion.defaultDuration;

  Curve get _curve => widget.curve ?? _motion.defaultCurve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _transition = ValueTransition.initial(widget.value);

    final String text = _formatter.format(widget.value);
    _toGlyphs = GlyphSpec.parse(text);
    _fromGlyphs = _toGlyphs;
    _instructions = GlyphDiffer.align(_fromGlyphs, _toGlyphs);

    if (widget.animateOnFirstBuild) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 1;
    }
    _publishAfterFrame(_transition);
  }

  @override
  void didUpdateWidget(MotionNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.duration = _duration;

    final bool valueChanged = widget.value != oldWidget.value;
    final bool formattingChanged =
        widget.formatter != oldWidget.formatter ||
        widget.tabularFigures != oldWidget.tabularFigures;

    if (valueChanged) {
      _startTransition(from: oldWidget.value, to: widget.value);
    } else if (formattingChanged) {
      // Same number, different text: re-derive without animating.
      _toGlyphs = GlyphSpec.parse(_formatter.format(widget.value));
      _fromGlyphs = _toGlyphs;
      _instructions = GlyphDiffer.align(_fromGlyphs, _toGlyphs);
      _controller.value = 1;
    }
  }

  /// Begins a new transition, snapshotting anything currently on screen.
  ///
  /// Resuming from the abandoned target would visibly rewind, so an
  /// interruption diffs from the digits the user can actually see right now and
  /// restarts the controller at zero.
  void _startTransition({required num from, required num to}) {
    final bool interrupting =
        _controller.isAnimating && _controller.value < 1.0;

    _fromGlyphs = interrupting
        ? _visibleGlyphs()
        : GlyphSpec.parse(_formatter.format(from));
    _toGlyphs = GlyphSpec.parse(_formatter.format(to));
    _instructions = GlyphDiffer.align(_fromGlyphs, _toGlyphs);

    _transition = ValueTransition.between(from, to);
    widget.onTransition?.call(_transition);
    _publishAfterFrame(_transition);

    _controller
      ..duration = _duration
      ..forward(from: 0);
  }

  /// The glyphs on screen at this instant, used when a transition is cut short.
  List<GlyphSpec> _visibleGlyphs() {
    final double globalT = _curve.transform(_controller.value.clamp(0.0, 1.0));
    final int slotCount = _instructions.length;
    final StringBuffer buffer = StringBuffer();

    for (int i = 0; i < slotCount; i++) {
      final SlotInstruction instruction = _instructions[i];
      switch (instruction) {
        case RollSlot():
          final double t = _motion.localT(
            globalT,
            i,
            slotCount,
            _transition.direction,
          );
          buffer.write(
            _motion.visibleDigit(_snapshotData(instruction, i, slotCount), t),
          );
        case StaticSlot(:final String char):
          buffer.write(char);
        case EnterSlot(:final GlyphSpec glyph):
          // Already at least partly on screen; keep it.
          buffer.write(glyph.char);
        case ExitSlot():
          // On its way out; treat it as gone.
          break;
      }
    }
    return GlyphSpec.parse(buffer.toString());
  }

  /// Minimal render data for a digit query, with no strip attached.
  SlotRenderData _snapshotData(
    SlotInstruction instruction,
    int index,
    int slotCount,
  ) => SlotRenderData(
    instruction: instruction,
    slotIndex: index,
    slotCount: slotCount,
    direction: _transition.direction,
    cellSize: Size.zero,
    textStyle: const TextStyle(),
    strip: null,
    stripRepeats: _motion.stripRepeats,
  );

  /// Publishes into an ancestor scope after the current frame.
  ///
  /// Deferred because notifying during build would mark an already-built
  /// ancestor dirty.
  void _publishAfterFrame(ValueTransition transition) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        MotionNumberScope.publish(context, transition);
      }
    });
  }

  /// Builds the digit column once, reusing it until the style or size changes.
  Widget _stripFor(TextStyle style, Size cell, int repeats) {
    if (_strip != null &&
        _stripStyle == style &&
        _stripCell == cell &&
        _stripRepeats == repeats) {
      return _strip!;
    }
    _stripStyle = style;
    _stripCell = cell;
    _stripRepeats = repeats;
    _strip = Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (int repeat = 0; repeat < repeats; repeat++)
          for (int digit = 0; digit <= 9; digit++)
            SizedBox(
              width: cell.width,
              height: cell.height,
              child: Center(child: Text('$digit', style: style)),
            ),
      ],
    );
    return _strip!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle base =
        widget.textStyle ?? DefaultTextStyle.of(context).style;
    final Color? tint = widget.directionColors?.resolve(_transition.direction);
    final TextStyle styled = tint == null ? base : base.copyWith(color: tint);
    final TextStyle resolved = widget.tabularFigures
        ? DigitMetrics.withTabularFigures(styled)
        : styled;

    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final Size cell = DigitMetrics.measure(resolved, textScaler: textScaler);
    final DigitMotion motion = _motion;
    final Widget strip = _stripFor(resolved, cell, motion.stripRepeats);

    // Correct value, no motion: the accessibility short-circuit.
    final bool animationsDisabled = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label: _formatter.format(widget.value),
      liveRegion: true,
      container: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? _) {
          final double globalT = animationsDisabled
              ? 1.0
              : _curve.transform(_controller.value.clamp(0.0, 1.0));
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              for (int i = 0; i < _instructions.length; i++)
                _buildSlot(context, motion, resolved, cell, strip, i, globalT),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSlot(
    BuildContext context,
    DigitMotion motion,
    TextStyle style,
    Size cell,
    Widget strip,
    int index,
    double globalT,
  ) {
    final SlotInstruction instruction = _instructions[index];
    final int slotCount = _instructions.length;
    final MotionDirection direction = _transition.direction;
    final double t = motion.localT(globalT, index, slotCount, direction);

    SlotRenderData dataFor(SlotInstruction resolvedInstruction) =>
        SlotRenderData(
          instruction: resolvedInstruction,
          slotIndex: index,
          slotCount: slotCount,
          direction: direction,
          cellSize: cell,
          textStyle: style,
          strip: strip,
          stripRepeats: motion.stripRepeats,
          color: widget.directionColors?.resolve(direction),
        );

    switch (instruction) {
      case RollSlot():
        return DigitCell(motion: motion, data: dataFor(instruction), t: t);

      case StaticSlot(:final String char):
        return SeparatorCell(char: char, textStyle: style);

      case EnterSlot(:final GlyphSpec glyph):
        // Entering slots widen from nothing so the row pushes open.
        return _buildAppearing(
          motion: motion,
          dataFor: dataFor,
          glyph: glyph,
          style: style,
          t: t,
          factor: t,
        );

      case ExitSlot(:final GlyphSpec glyph):
        return _buildAppearing(
          motion: motion,
          dataFor: dataFor,
          glyph: glyph,
          style: style,
          t: t,
          factor: 1 - t,
        );
    }
  }

  /// Renders an entering or exiting slot at [factor] of its full width.
  Widget _buildAppearing({
    required DigitMotion motion,
    required SlotRenderData Function(SlotInstruction) dataFor,
    required GlyphSpec glyph,
    required TextStyle style,
    required double t,
    required double factor,
  }) {
    if (glyph is DigitGlyph) {
      // A held digit, so the style's look still applies while it widens.
      final RollSlot held = RollSlot(
        from: glyph.digit,
        to: glyph.digit,
        placeIndex: glyph.placeIndex,
      );
      return DigitCell(
        motion: motion,
        data: dataFor(held),
        t: t,
        widthFactor: factor,
        opacity: factor,
      );
    }
    return SeparatorCell(
      char: glyph.char,
      textStyle: style,
      widthFactor: factor,
      opacity: factor,
    );
  }
}
