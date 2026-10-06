/// The bell mascot (DS8). Vector stand-in drawn in code until the AI → Rive asset (DS9) exists;
/// same moods as the planned state machine. Appears only in onboarding, empty states and celebrations.
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

enum BellMood { calm, happy, ringing, thinking, party }

class Bell extends StatefulWidget {
  const Bell({super.key, this.size = 96, this.mood = BellMood.calm});
  final double size;
  final BellMood mood;

  @override
  State<Bell> createState() => _BellState();
}

class _BellState extends State<Bell> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _period(widget.mood))..repeat();
  }

  @override
  void didUpdateWidget(Bell old) {
    super.didUpdateWidget(old);
    if (old.mood != widget.mood) _c.duration = _period(widget.mood);
    if (!_c.isAnimating) _c.repeat();
  }

  static Duration _period(BellMood m) => switch (m) {
    BellMood.ringing => const Duration(milliseconds: 700),
    BellMood.happy || BellMood.party => const Duration(milliseconds: 1200),
    _ => const Duration(milliseconds: 3200),
  };

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => CustomPaint(
            painter: _BellPainter(
              t: reduceMotion ? 0 : _c.value,
              mood: widget.mood,
              dark: Theme.of(context).brightness == Brightness.dark,
            ),
          ),
        ),
      ),
    );
  }
}

class _BellPainter extends CustomPainter {
  _BellPainter({required this.t, required this.mood, required this.dark});
  final double t;
  final BellMood mood;
  final bool dark;

  static const _gold = Color(0xFFFFC53D);
  static const _goldDark = Color(0xFFF2A007);
  static const _ink = Color(0xFF3A2A12);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final wave = math.sin(t * 2 * math.pi);
    final swing = switch (mood) {
      BellMood.ringing => wave * 0.26,
      BellMood.happy || BellMood.party => wave * 0.08,
      BellMood.thinking => wave * 0.04 - 0.08,
      BellMood.calm => wave * 0.05,
    };
    final bounce = (mood == BellMood.happy || mood == BellMood.party) ? -wave.abs() * s * 0.04 : 0.0;

    // Soft shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(s * 0.5, s * 0.93), width: s * 0.5, height: s * 0.07),
      Paint()..color = Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
    );

    if (mood == BellMood.party) _confetti(canvas, s);
    if (mood == BellMood.ringing) _soundWaves(canvas, s, wave);

    canvas.save();
    canvas.translate(s * 0.5, s * 0.12 + bounce);
    canvas.rotate(swing);
    canvas.translate(-s * 0.5, -s * 0.12);

    // Hanger loop
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.12),
      s * 0.055,
      Paint()
        ..color = _goldDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03,
    );

    // Clapper (swings opposite)
    final clapX = s * 0.5 - swing * s * 0.25;
    canvas.drawCircle(Offset(clapX, s * 0.8), s * 0.07, Paint()..color = _goldDark);

    // Body
    final body = Path()
      ..moveTo(s * 0.5, s * 0.16)
      ..cubicTo(s * 0.27, s * 0.16, s * 0.24, s * 0.36, s * 0.24, s * 0.5)
      ..cubicTo(s * 0.24, s * 0.62, s * 0.2, s * 0.68, s * 0.13, s * 0.74)
      ..quadraticBezierTo(s * 0.11, s * 0.78, s * 0.16, s * 0.78)
      ..lineTo(s * 0.84, s * 0.78)
      ..quadraticBezierTo(s * 0.89, s * 0.78, s * 0.87, s * 0.74)
      ..cubicTo(s * 0.8, s * 0.68, s * 0.76, s * 0.62, s * 0.76, s * 0.5)
      ..cubicTo(s * 0.76, s * 0.36, s * 0.73, s * 0.16, s * 0.5, s * 0.16)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_gold, _goldDark],
        ).createShader(Rect.fromLTWH(0, 0, s, s)),
    );
    // Rim
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(s * 0.12, s * 0.74, s * 0.76, s * 0.06), Radius.circular(s * 0.03)),
      Paint()..color = _goldDark,
    );
    // Highlight
    canvas.drawPath(
      Path()
        ..moveTo(s * 0.36, s * 0.3)
        ..quadraticBezierTo(s * 0.31, s * 0.42, s * 0.32, s * 0.55),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = s * 0.035,
    );

    _face(canvas, s);
    canvas.restore();
  }

  void _face(Canvas canvas, double s) {
    final ink = Paint()..color = _ink;
    final stroke = Paint()
      ..color = _ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.028;
    final eyeY = s * 0.5;
    // Blink every few seconds when calm.
    final blink = mood == BellMood.calm && t > 0.92;
    for (final x in [s * 0.42, s * 0.58]) {
      if (mood == BellMood.happy || mood == BellMood.party) {
        canvas.drawArc(Rect.fromCenter(center: Offset(x, eyeY + s * 0.01), width: s * 0.07, height: s * 0.06),
            math.pi, math.pi, false, stroke);
      } else if (blink) {
        canvas.drawLine(Offset(x - s * 0.025, eyeY), Offset(x + s * 0.025, eyeY), stroke);
      } else {
        canvas.drawOval(Rect.fromCenter(center: Offset(x, eyeY), width: s * 0.05, height: s * 0.065), ink);
      }
    }
    // Cheeks
    final cheek = Paint()..color = const Color(0xFFFF8A65).withValues(alpha: 0.45);
    canvas.drawCircle(Offset(s * 0.35, s * 0.57), s * 0.03, cheek);
    canvas.drawCircle(Offset(s * 0.65, s * 0.57), s * 0.03, cheek);
    // Mouth
    switch (mood) {
      case BellMood.thinking:
        canvas.drawLine(Offset(s * 0.47, s * 0.6), Offset(s * 0.54, s * 0.59), stroke);
      case BellMood.ringing:
        canvas.drawOval(Rect.fromCenter(center: Offset(s * 0.5, s * 0.6), width: s * 0.06, height: s * 0.07), ink);
      default:
        canvas.drawArc(Rect.fromCenter(center: Offset(s * 0.5, s * 0.575), width: s * 0.1, height: s * 0.07),
            0.15, math.pi - 0.3, false, stroke);
    }
  }

  void _soundWaves(Canvas canvas, double s, double wave) {
    final p = Paint()
      ..color = _goldDark.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * 0.025;
    for (final side in [-1.0, 1.0]) {
      for (var i = 0; i < 2; i++) {
        final r = s * (0.12 + i * 0.08) * (1 + wave.abs() * 0.1);
        final c = Offset(s * 0.5 + side * s * 0.36, s * 0.42);
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), side < 0 ? math.pi * 0.75 : -math.pi * 0.25,
            math.pi * 0.5, false, p);
      }
    }
  }

  void _confetti(Canvas canvas, double s) {
    const colors = [Color(0xFFFF2D55), Color(0xFF34C759), Color(0xFF007AFF), Color(0xFF5856D6), Color(0xFFFF9500)];
    final rnd = math.Random(7);
    for (var i = 0; i < 14; i++) {
      final x = rnd.nextDouble() * s;
      final y = ((rnd.nextDouble() + t) % 1.0) * s * 0.9;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * 6 + i);
      canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: s * 0.04, height: s * 0.018),
          Paint()..color = colors[i % colors.length]);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_BellPainter old) => old.t != t || old.mood != mood || old.dark != dark;
}
