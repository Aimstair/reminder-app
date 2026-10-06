// Scene A — onboarding "Nudged before it matters" demo (design-direction §5, step 3) — mirrors RN NudgesScene
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../theme.dart';
import '../widgets/bell.dart';

const _knob = 28.0;
const _days = ['Oct 5', '6', '7', '8', '9', '10', '11', 'Oct 12'];

class _Card {
  final int stage;
  final String title, body;
  final bool prep;
  const _Card(this.stage, this.title, this.body, this.prep);
}

const _cards = [
  _Card(1, "Mom's birthday", 'In 1 week · Mon, Oct 12', true),
  _Card(2, "Mom's birthday", 'In 1 day · Tomorrow', true),
  _Card(3, "Mom's birthday", 'Today 🎂', false),
];

class NudgesScene extends StatefulWidget {
  final VoidCallback onTick;
  const NudgesScene({super.key, required this.onTick});

  @override
  State<NudgesScene> createState() => _NudgesSceneState();
}

class _NudgesSceneState extends State<NudgesScene> with SingleTickerProviderStateMixin {
  late final _x = AnimationController.unbounded(vsync: this)..addListener(_onMove);
  double _max = 1;
  int _stage = 0;
  bool _prepared = false;
  Mood _mood = Mood.idle;
  Timer? _moodTimer;

  void _onMove() {
    final p = _x.value / _max;
    final s = p < 0.03 ? 0 : p < 6 / 7 - 0.02 ? 1 : p < 0.985 ? 2 : 3;
    if (s == _stage) return;
    setState(() => _stage = s);
    if (s == 0) return;
    widget.onTick();
    if (_prepared && s < 3) return;
    setState(() => _mood = Mood.nudge);
    _moodTimer?.cancel();
    _moodTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _mood = _prepared ? Mood.happy : Mood.idle);
    });
  }

  void _snap() {
    final step = _max / 7;
    final target = (_x.value / step).round() * step;
    _x.animateWith(SpringSimulation(Springs.snappy, _x.value, target, 0));
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    _x.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final visible = _cards.where((k) => k.stage <= _stage && !(_prepared && k.prep)).toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: Space.s),
          Text('Nudged before it matters.', style: AppText.largeTitle.copyWith(color: c.textPrimary)),
          const SizedBox(height: Space.s),
          Text('Drag through the week. For big days, you get a heads-up early — not just on the day.',
              style: AppText.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: Space.xl),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(Space.l),
              decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(36), border: Border.all(color: c.separator)),
              child: Column(
                children: [
                  Bell(mood: _mood, size: 110),
                  const SizedBox(height: Space.l),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 350),
                    curve: const SpringCurve(Springs.soft),
                    alignment: Alignment.topCenter,
                    child: Column(
                      children: [
                        for (final k in visible)
                          _SlideIn(
                            key: ValueKey(k.stage),
                            child: Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(bottom: Space.s),
                              padding: const EdgeInsets.all(Space.m),
                              decoration: BoxDecoration(color: c.bgGrouped, borderRadius: BorderRadius.circular(Radii.card)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(k.title, style: AppText.headline.copyWith(color: c.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(k.body, style: AppText.subheadline.copyWith(color: c.textSecondary)),
                                  if (k.prep && !_prepared)
                                    GestureDetector(
                                      onTap: () => setState(() {
                                        _prepared = true;
                                        _mood = Mood.happy;
                                      }),
                                      child: Container(
                                        margin: const EdgeInsets.only(top: Space.s),
                                        padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 6),
                                        decoration: BoxDecoration(color: c.kind[Kind.occasion], borderRadius: BorderRadius.circular(Radii.chip)),
                                        child: const Text("I'm prepared",
                                            style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white)),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        if (_prepared && _stage < 3)
                          _SlideIn(
                            key: const ValueKey('prepared'),
                            child: Text("Prepared? We'll stop the early nudges.",
                                textAlign: TextAlign.center, style: AppText.footnote.copyWith(color: c.textSecondary)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.xl),
            child: LayoutBuilder(builder: (context, box) {
              _max = (box.maxWidth - _knob).clamp(1, double.infinity);
              return Column(
                children: [
                  SizedBox(
                    height: _knob,
                    child: AnimatedBuilder(
                      animation: _x,
                      builder: (context, _) => Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(height: 6, decoration: BoxDecoration(color: c.separator, borderRadius: BorderRadius.circular(3))),
                          Container(
                            height: 6,
                            width: _x.value + _knob / 2,
                            decoration: BoxDecoration(color: c.kind[Kind.occasion], borderRadius: BorderRadius.circular(3)),
                          ),
                          Positioned(
                            left: _x.value,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onHorizontalDragUpdate: (d) {
                                _x.stop();
                                _x.value = (_x.value + d.delta.dx).clamp(0, _max);
                              },
                              onHorizontalDragEnd: (_) => _snap(),
                              child: Container(
                                width: _knob,
                                height: _knob,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Space.m),
                  Row(
                    children: [
                      for (final d in _days)
                        Expanded(child: Text(d, textAlign: TextAlign.center, style: AppText.caption.copyWith(color: c.textSecondary))),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _prepared = false;
                        _mood = Mood.idle;
                      });
                      _x.animateWith(SpringSimulation(Springs.soft, _x.value, 0, 0));
                    },
                    child: Text('Reset', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: c.accent)),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Spring slide-in from above (matches Reanimated SlideInUp.springify()).
class _SlideIn extends StatefulWidget {
  final Widget child;
  const _SlideIn({super.key, required this.child});
  @override
  State<_SlideIn> createState() => _SlideInState();
}

class _SlideInState extends State<_SlideIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: const SpringCurve(Springs.soft, seconds: 0.5));
    return FadeTransition(
      opacity: _c,
      child: SlideTransition(position: Tween(begin: const Offset(0, -0.6), end: Offset.zero).animate(curved), child: widget.child),
    );
  }
}
