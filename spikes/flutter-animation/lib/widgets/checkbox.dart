// Things-style round checkbox: fill springs 1 → 1.15 → 1, checkmark draws in (design-direction §6 step 1)
import 'package:flutter/material.dart';

class RoundCheckbox extends StatefulWidget {
  final bool checked;
  final Color color;
  final VoidCallback onTap;
  final double size;
  const RoundCheckbox({super.key, required this.checked, required this.color, required this.onTap, this.size = 26});

  @override
  State<RoundCheckbox> createState() => _RoundCheckboxState();
}

class _RoundCheckboxState extends State<RoundCheckbox> with TickerProviderStateMixin {
  late final _fill = AnimationController(vsync: this, duration: const Duration(milliseconds: 160), value: widget.checked ? 1 : 0);
  late final _draw = AnimationController(vsync: this, duration: const Duration(milliseconds: 220), value: widget.checked ? 1 : 0);
  late final _pop = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)), weight: 60),
  ]).animate(_pop);

  @override
  void didUpdateWidget(covariant RoundCheckbox old) {
    super.didUpdateWidget(old);
    if (widget.checked == old.checked) return;
    if (widget.checked) {
      _fill.forward();
      _pop.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 90), () {
        if (mounted) _draw.forward();
      });
    } else {
      _draw.reverse();
      _fill.reverse();
    }
  }

  @override
  void dispose() {
    _fill.dispose();
    _draw.dispose();
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      checked: widget.checked,
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AnimatedBuilder(
            animation: Listenable.merge([_fill, _draw, _pop]),
            builder: (context, _) => Transform.scale(
              scale: reduce ? 1 : _scale.value,
              child: CustomPaint(
                size: Size.square(widget.size),
                painter: _CheckPainter(color: widget.color, fill: _fill.value, draw: _draw.value),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final Color color;
  final double fill, draw;
  _CheckPainter({required this.color, required this.fill, required this.draw});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final c = Offset(12 * s, 12 * s);
    canvas.drawCircle(c, 10.5 * s, Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 * s);
    if (fill > 0) canvas.drawCircle(c, 10.5 * s * fill, Paint()..color = color);
    if (draw > 0) {
      final path = Path()
        ..moveTo(7.2 * s, 12.4 * s)
        ..lineTo(10.6 * s, 15.8 * s)
        ..lineTo(17 * s, 9.2 * s);
      final metric = path.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * draw),
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * s
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.fill != fill || old.draw != draw || old.color != color;
}
