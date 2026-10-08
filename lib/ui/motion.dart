/// Shared motion pieces (design-direction.md §5, DS14): iOS-style press feedback, a selection
/// highlight that slides to the chosen option, staggered entrances and counting numbers.
/// Every animation respects Reduce Motion (MediaQuery.disableAnimations → no movement).
library;

import 'package:flutter/material.dart';

import 'tokens.dart';

bool reduceMotion(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Shrinks slightly and dims while pressed, then springs back (iOS buttons and cards).
class Pressable extends StatefulWidget {
  const Pressable({super.key, required this.child, this.onTap, this.onLongPress, this.scale = 0.97});
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    final pressed = _down && enabled && !reduceMotion(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: () => _set(false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: pressed ? widget.scale : 1,
        duration: pressed ? Motion.micro : Motion.standard,
        curve: pressed ? Curves.easeOut : Motion.spring,
        child: AnimatedOpacity(opacity: pressed ? 0.85 : 1, duration: Motion.micro, child: widget.child),
      ),
    );
  }
}

/// Fades and slides its child up into place once, [index] × 35 ms after first build (lists,
/// cards). Rebuilds don't replay it.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({super.key, required this.child, this.index = 0, this.offset = 14});
  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Motion.emphasized);
  late final _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    final delay = Duration(milliseconds: 35 * widget.index.clamp(0, 10));
    Future<void>.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) _c.value = 1;
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (_, child) => Opacity(
      opacity: _t.value,
      child: Transform.translate(offset: Offset(0, widget.offset * (1 - _t.value)), child: child),
    ),
  );
}

/// A highlight that travels to the selected child — for rows of options with different widths
/// (filter chips, tabs). Children are laid out in a Row; [highlight] is drawn behind the selected
/// one and animates its position and width when [selected] changes.
class SlidingHighlightRow extends StatefulWidget {
  const SlidingHighlightRow({
    super.key,
    required this.children,
    required this.selected,
    required this.highlight,
    this.spacing = Space.s,
  });
  final List<Widget> children;
  final int selected;
  final Widget highlight;
  final double spacing;

  @override
  State<SlidingHighlightRow> createState() => _SlidingHighlightRowState();
}

class _SlidingHighlightRowState extends State<SlidingHighlightRow> {
  final _rowKey = GlobalKey();
  late List<GlobalKey> _keys = [for (final _ in widget.children) GlobalKey()];
  Rect? _rect;

  @override
  void didUpdateWidget(SlidingHighlightRow old) {
    super.didUpdateWidget(old);
    if (old.children.length != widget.children.length) _keys = [for (final _ in widget.children) GlobalKey()];
    _measureLater();
  }

  @override
  void initState() {
    super.initState();
    _measureLater();
  }

  void _measureLater() => WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

  void _measure() {
    if (!mounted || widget.selected < 0 || widget.selected >= _keys.length) return;
    final row = _rowKey.currentContext?.findRenderObject() as RenderBox?;
    final box = _keys[widget.selected].currentContext?.findRenderObject() as RenderBox?;
    if (row == null || box == null || !row.hasSize || !box.hasSize) return;
    final r = box.localToGlobal(Offset.zero, ancestor: row) & box.size;
    if (r != _rect) setState(() => _rect = r);
  }

  @override
  Widget build(BuildContext context) {
    final r = _rect;
    return Stack(
      key: _rowKey,
      children: [
        if (r != null)
          AnimatedPositioned(
            duration: reduceMotion(context) ? Duration.zero : Motion.standard,
            curve: Motion.spring,
            left: r.left,
            top: r.top,
            width: r.width,
            height: r.height,
            child: widget.highlight,
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < widget.children.length; i++) ...[
              if (i > 0) SizedBox(width: widget.spacing),
              KeyedSubtree(key: _keys[i], child: widget.children[i]),
            ],
          ],
        ),
      ],
    );
  }
}

/// Equal-width cells with a highlight that slides to [selected] (segmented controls, week and day
/// strips). [cell] builds each cell's content; [highlight] is drawn under the selected cell.
class SlidingCells extends StatelessWidget {
  const SlidingCells({
    super.key,
    required this.count,
    required this.selected,
    required this.cell,
    required this.highlight,
    this.height,
    this.inset = EdgeInsets.zero,
  });
  final int count;

  /// Null or out of range hides the highlight.
  final int? selected;
  final Widget Function(BuildContext context, int index) cell;
  final Widget highlight;
  final double? height;

  /// Space between a cell's edge and the highlight.
  final EdgeInsets inset;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    child: LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth / count;
        final sel = selected;
        final show = sel != null && sel >= 0 && sel < count;
        return Stack(
          children: [
            AnimatedPositioned(
              duration: reduceMotion(context) ? Duration.zero : Motion.standard,
              curve: Motion.spring,
              left: (show ? sel : 0) * w + inset.left,
              width: w - inset.horizontal,
              top: inset.top,
              bottom: inset.bottom,
              child: AnimatedOpacity(opacity: show ? 1 : 0, duration: Motion.micro, child: highlight),
            ),
            // Filled and stretched so each cell's content centres vertically in the track.
            Positioned.fill(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [for (var i = 0; i < count; i++) SizedBox(width: w, child: cell(context, i))],
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// A number that counts to its new value (progress, "3 left").
class CountText extends StatelessWidget {
  const CountText(this.value, {super.key, this.style, this.format});
  final int value;
  final TextStyle? style;
  final String Function(int)? format;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: value.toDouble()),
    duration: reduceMotion(context) ? Duration.zero : Motion.emphasized,
    curve: Curves.easeOutCubic,
    builder: (_, v, _) {
      final n = v.round();
      return Text(format?.call(n) ?? '$n', style: style, maxLines: 1);
    },
  );
}

/// Cross-fades with a small scale and slide when [child]'s key changes (view and page switches).
class SwapFade extends StatelessWidget {
  const SwapFade({super.key, required this.child, this.slide = Offset.zero, this.duration = Motion.standard});
  final Widget child;

  /// Direction the new child comes from, as a fraction of its size (e.g. Offset(0.06, 0)).
  final Offset slide;
  final Duration duration;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: reduceMotion(context) ? Duration.zero : duration,
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeInCubic,
    layoutBuilder: (current, previous) => Stack(alignment: Alignment.topCenter, children: [...previous, ?current]),
    transitionBuilder: (child, a) {
      final incoming = child.key == this.child.key;
      final from = incoming ? slide : -slide;
      return FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween(begin: from, end: Offset.zero).animate(a),
          child: ScaleTransition(scale: Tween(begin: 0.98, end: 1.0).animate(a), child: child),
        ),
      );
    },
    child: child,
  );
}

/// Gently bobs and tilts its child (illustrations, floating cards). [phase] (0–1) offsets several
/// floaters so they don't move in sync. Holds still under Reduce Motion.
class Floating extends StatefulWidget {
  const Floating({
    super.key,
    required this.child,
    this.amplitude = 6,
    this.period = const Duration(seconds: 3),
    this.phase = 0,
  });
  final Widget child;
  final double amplitude;
  final Duration period;
  final double phase;

  @override
  State<Floating> createState() => _FloatingState();
}

class _FloatingState extends State<Floating> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: widget.period, value: widget.phase);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    child: widget.child,
    builder: (_, child) {
      final t = Curves.easeInOut.transform(_c.value);
      return Transform.translate(
        offset: Offset(0, -widget.amplitude * t),
        child: Transform.rotate(angle: 0.04 * (t - 0.5), child: child),
      );
    },
  );
}
