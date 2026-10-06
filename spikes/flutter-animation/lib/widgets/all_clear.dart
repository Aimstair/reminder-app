// Scene D — "All clear" milestone: bell happy + confetti, ≤ 1.5 s, tap to skip (design-direction §6)
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'bell.dart';

class AllClear extends StatefulWidget {
  final VoidCallback onDone;
  const AllClear({super.key, required this.onDone});

  @override
  State<AllClear> createState() => _AllClearState();
}

class _Piece {
  final double x, dx, dy, rot, delay, w;
  final Color color;
  _Piece(this.x, this.dx, this.dy, this.rot, this.delay, this.w, this.color);
}

class _AllClearState extends State<AllClear> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1420))..forward();
  late final Timer _timer = Timer(const Duration(milliseconds: 1500), widget.onDone);
  List<_Piece>? _pieces;

  @override
  void initState() {
    super.initState();
    _timer; // start
  }

  @override
  void dispose() {
    _timer.cancel();
    _c.dispose();
    super.dispose();
  }

  List<_Piece> _make(Size s, AppColors c) {
    final r = math.Random();
    final colors = [c.kind[Kind.task]!, c.kind[Kind.meeting]!, c.kind[Kind.event]!, c.kind[Kind.occasion]!, c.success, const Color(0xFFFFCC00)];
    return List.generate(48, (i) => _Piece(
          s.width / 2 + (r.nextDouble() - 0.5) * 60,
          (r.nextDouble() - 0.5) * s.width * 1.1,
          s.height * (0.45 + r.nextDouble() * 0.5),
          (r.nextDouble() - 0.5) * 4 * math.pi,
          r.nextDouble() * 120,
          6 + r.nextDouble() * 6,
          colors[i % colors.length],
        ));
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final size = MediaQuery.sizeOf(context);
    _pieces ??= _make(size, c);
    return GestureDetector(
      onTap: widget.onDone,
      child: Container(
        color: const Color(0x1F7F7F7F),
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_pieces!, _c.value * 1420, size)),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Bell(mood: Mood.happy, size: 160),
                  Text('All clear!', style: AppText.largeTitle.copyWith(color: c.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Nothing left for today.', style: AppText.body.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Piece> pieces;
  final double ms;
  final Size screen;
  _ConfettiPainter(this.pieces, this.ms, this.screen);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final raw = ((ms - p.delay) / 1300).clamp(0.0, 1.0);
      final v = Curves.easeOutQuad.transform(raw);
      if (raw <= 0) continue;
      final x = p.x + p.dx * v;
      final y = screen.height * 0.35 - screen.height * 0.25 * math.sin(math.pi * v) + p.dy * v * v;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.rot * v);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, p.w, p.w * 1.6), const Radius.circular(2)),
        Paint()..color = p.color.withValues(alpha: 1 - v * v),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.ms != ms;
}
