// Scene B (list + completion), C (capture sheet), D (All clear) — docs/spikes/animation-bakeoff.md
import 'dart:async';

import 'package:flutter/material.dart';

import '../data.dart';
import '../feedback.dart';
import '../theme.dart';
import '../widgets/all_clear.dart';
import '../widgets/capture_sheet.dart';
import '../widgets/reminder_row.dart';

sealed class _Item {
  String get id;
}

class _Header extends _Item {
  final Group group;
  _Header(this.group);
  @override
  String get id => 'h-${group.name}';
}

class _Row extends _Item {
  final Reminder r;
  _Row(this.r);
  @override
  String get id => r.id;
}

List<_Item> _flatten(List<Reminder> list) {
  final out = <_Item>[];
  for (final g in Group.values) {
    final rows = list.where((r) => r.group == g).toList();
    if (rows.isEmpty) continue;
    out.add(_Header(g));
    out.addAll(rows.map(_Row.new));
  }
  return out;
}

class ScheduleScene extends StatefulWidget {
  final AppFeedback feedback;
  const ScheduleScene({super.key, required this.feedback});

  @override
  State<ScheduleScene> createState() => _ScheduleSceneState();
}

class _ScheduleSceneState extends State<ScheduleScene> {
  final _listKey = GlobalKey<SliverAnimatedListState>();
  List<Reminder> _list = makeReminders(200);
  late List<_Item> _items = _flatten(_list);
  ({Reminder item, int index})? _lastRemoved;
  String? _newId;
  bool _celebrating = false;
  final Set<String> _autoIds = {};

  /// Animate the AnimatedList from the current items to [next] by diffing ids.
  void _apply(List<Reminder> next) {
    final old = _items;
    final nu = _flatten(next);
    final nuIds = nu.map((e) => e.id).toSet();
    for (var i = old.length - 1; i >= 0; i--) {
      if (!nuIds.contains(old[i].id)) {
        final removed = old[i];
        _listKey.currentState?.removeItem(
          i,
          (context, anim) => _removedBuilder(removed, anim),
          duration: const Duration(milliseconds: 280),
        );
      }
    }
    final oldIds = old.map((e) => e.id).toSet();
    _items = nu;
    _list = next;
    for (var i = 0; i < nu.length; i++) {
      if (!oldIds.contains(nu[i].id)) _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 420));
    }
    setState(() {});
  }

  void _onCompleted(Reminder item) {
    final index = _list.indexWhere((r) => r.id == item.id);
    if (index < 0) return;
    final next = [..._list]..removeAt(index);
    _lastRemoved = (item: item, index: index);
    _apply(next);
    final todayLeft = next.any((r) => r.group == Group.today);
    if (item.group == Group.today && !todayLeft && !MediaQuery.disableAnimationsOf(context)) {
      setState(() => _celebrating = true);
      widget.feedback.celebrate();
    }
  }

  void _undo() {
    final last = _lastRemoved;
    if (last == null) return;
    _newId = last.item.id;
    _lastRemoved = null;
    _apply([..._list]..insert(last.index.clamp(0, _list.length), last.item));
  }

  Future<void> _capture() async {
    final p = await showCaptureSheet(context);
    if (p == null) return;
    final r = Reminder(id: 'new-${DateTime.now().millisecondsSinceEpoch}', title: p.title, when: p.when, kind: p.kind, group: Group.today, work: false);
    _newId = r.id;
    _apply([r, ..._list]);
  }

  // Rapid test: complete the next 10 rows, one every 400 ms (bake-off Scene B)
  void _rapid() {
    final ids = _list.take(10).map((r) => r.id).toList();
    for (var i = 0; i < ids.length; i++) {
      Timer(Duration(milliseconds: i * 400), () {
        if (mounted) setState(() => _autoIds.add(ids[i]));
      });
    }
  }

  Widget _buildItem(_Item item) {
    final c = AppColors.of(context);
    return switch (item) {
      _Header(:final group) => Padding(
          padding: const EdgeInsets.fromLTRB(Space.l + 4, Space.xl, Space.l, Space.s),
          child: Text(group.label, style: AppText.headline.copyWith(color: group == Group.overdue ? c.danger : c.textPrimary)),
        ),
      _Row(:final r) => ReminderRow(
          key: ValueKey(r.id),
          item: r,
          onCompleted: _onCompleted,
          onFeedback: widget.feedback.complete,
          autoComplete: _autoIds.contains(r.id),
        ),
    };
  }

  Widget _removedBuilder(_Item item, Animation<double> anim) {
    final curved = CurvedAnimation(parent: anim, curve: Curves.easeInOut);
    return SizeTransition(
      sizeFactor: curved,
      child: FadeTransition(opacity: curved, child: IgnorePointer(child: _buildItem(item))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _titleRow(c)),
            SliverAnimatedList(
          key: _listKey,
          initialItemCount: _items.length,
          itemBuilder: (context, i, anim) {
            final item = _items[i];
            final isNew = item.id == _newId;
            final curved = CurvedAnimation(parent: anim, curve: const SpringCurve(Springs.soft));
            Widget child = _buildItem(item);
            if (isNew) {
              child = SlideTransition(
                position: Tween(begin: const Offset(0, 0.6), end: Offset.zero).animate(curved),
                child: FadeTransition(opacity: anim, child: child),
              );
            }
            return SizeTransition(sizeFactor: curved, child: child);
          },
            ),
            SliverPadding(padding: EdgeInsets.only(bottom: 120 + bottom)),
          ],
        ),
        Positioned(
          right: 20,
          bottom: 24 + bottom,
          child: GestureDetector(
            onTap: _capture,
            child: Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: c.accent,
                shape: BoxShape.circle,
                boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 4))],
              ),
              alignment: Alignment.center,
              child: const Text('+', style: TextStyle(color: Colors.white, fontSize: 32, height: 1.05)),
            ),
          ),
        ),
        Positioned(
          left: Space.l,
          right: Space.l,
          bottom: 96 + bottom,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: const SpringCurve(Springs.soft),
            transitionBuilder: (child, anim) => SlideTransition(
              position: Tween(begin: const Offset(0, 1.5), end: Offset.zero).animate(anim),
              child: child,
            ),
            child: _lastRemoved == null
                ? const SizedBox.shrink()
                : Container(
                    key: ValueKey(_lastRemoved!.item.id),
                    padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
                    decoration: BoxDecoration(color: const Color(0xFF1C1C1E), borderRadius: BorderRadius.circular(Radii.row)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Done', style: TextStyle(fontFamily: 'Inter', color: Colors.white, fontSize: 15)),
                        GestureDetector(
                          onTap: _undo,
                          child: const Text('Undo',
                              style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, color: Color(0xFF0A84FF), fontSize: 15)),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        if (_celebrating) Positioned.fill(child: AllClear(onDone: () => setState(() => _celebrating = false))),
      ],
    );
  }

  Widget _titleRow(AppColors c) => Padding(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Schedule', style: AppText.largeTitle.copyWith(color: c.textPrimary)),
            GestureDetector(
              onTap: _rapid,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 6),
                decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.chip)),
                child: Text('Rapid ×10', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 13, color: c.accent)),
              ),
            ),
          ],
        ),
      );
}
