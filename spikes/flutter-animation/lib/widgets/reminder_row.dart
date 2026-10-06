// Reminder row: completion animation (checkbox → strike-through → 600 ms hold → removal)
// and swipe right to complete — mirrors the RN ReminderRow.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../data.dart';
import '../theme.dart';
import 'checkbox.dart';

const _swipeDone = 90.0;
const _holdMs = 600;

class ReminderRow extends StatefulWidget {
  final Reminder item;
  final ValueChanged<Reminder> onCompleted;
  final VoidCallback onFeedback;
  final bool autoComplete;
  const ReminderRow({super.key, required this.item, required this.onCompleted, required this.onFeedback, this.autoComplete = false});

  @override
  State<ReminderRow> createState() => _ReminderRowState();
}

class _ReminderRowState extends State<ReminderRow> with TickerProviderStateMixin {
  bool _done = false;
  late final _strike = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  late final _swipe = AnimationController.unbounded(vsync: this);
  Timer? _timer;

  @override
  void didUpdateWidget(covariant ReminderRow old) {
    super.didUpdateWidget(old);
    if (widget.autoComplete && !old.autoComplete) _complete();
  }

  void _complete() {
    if (_done) return;
    setState(() => _done = true);
    widget.onFeedback();
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _strike.forward();
    });
    _timer = Timer(const Duration(milliseconds: 320 + _holdMs), () => widget.onCompleted(widget.item));
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _swipe.value = (_swipe.value + d.delta.dx).clamp(0, double.infinity);
  }

  void _onDragEnd(DragEndDetails d) {
    if (_swipe.value > _swipeDone) _complete();
    _swipe.animateWith(SpringSimulation(Springs.soft, _swipe.value, 0, d.primaryVelocity ?? 0));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _strike.dispose();
    _swipe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final item = widget.item;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: 3),
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _swipe,
              builder: (context, _) => Opacity(
                opacity: (_swipe.value / _swipeDone).clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(color: c.success, borderRadius: BorderRadius.circular(Radii.row)),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: Space.xl),
                  child: const Text('✓ Done', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: Colors.white)),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedBuilder(
              animation: _swipe,
              builder: (context, child) => Transform.translate(offset: Offset(_swipe.value, 0), child: child),
              child: Container(
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.row)),
                padding: const EdgeInsets.only(left: Space.xs, right: Space.l, top: Space.xs, bottom: Space.xs),
                child: Row(
                  children: [
                    RoundCheckbox(checked: _done, color: c.kind[item.kind]!, onTap: _complete),
                    const SizedBox(width: Space.xs),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Text(item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.body.copyWith(color: _done ? c.textSecondary : c.textPrimary)),
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _strike,
                                  builder: (context, _) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: _strike.value,
                                      child: Container(height: 1.5, color: c.textSecondary),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text('${item.when}${item.work ? '  · Work' : ''}',
                              style: AppText.subheadline.copyWith(color: item.group == Group.overdue ? c.danger : c.textSecondary)),
                        ],
                      ),
                    ),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: c.kind[item.kind], shape: BoxShape.circle)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
