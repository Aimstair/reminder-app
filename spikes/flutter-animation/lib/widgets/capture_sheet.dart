// Scene C — capture sheet: spring open, chips pop in one by one, save → row flies into the list.
// Stub parser only (keyword match) — identical rules to the RN spike's stubParse.
import 'dart:async';

import 'package:flutter/material.dart';

import '../theme.dart';

class ParsedChip {
  final String key, label;
  const ParsedChip(this.key, this.label);
}

class Parsed {
  final String title, when;
  final Kind kind;
  final List<ParsedChip> chips;
  const Parsed(this.title, this.when, this.kind, this.chips);
}

final _months = RegExp(r'\b(jan|feb|mar|apr|may|jun|jul|aug|sep|sept|oct|nov|dec)[a-z]*\.?\s+(\d{1,2})(st|nd|rd|th)?\b', caseSensitive: false);
final _time = RegExp(r'\b(\d{1,2})(:\d{2})?\s?(am|pm)\b', caseSensitive: false);
final _days = RegExp(r'\b(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b', caseSensitive: false);

String _cap(String s) => s.replaceAllMapped(RegExp(r'\b\w'), (m) => m[0]!.toUpperCase());

Parsed stubParse(String text) {
  var rest = text;
  final chips = <ParsedChip>[];
  final date = _months.firstMatch(text) ?? _days.firstMatch(text);
  var when = 'Tomorrow';
  if (date != null) {
    when = _cap(date[0]!);
    rest = rest.replaceFirst(date[0]!, '');
  }
  final time = _time.firstMatch(text);
  if (time != null) {
    when += ' · ${time[0]!.toUpperCase()}';
    rest = rest.replaceFirst(time[0]!, '');
  }
  final lower = text.toLowerCase();
  final kind = RegExp(r'birthday|anniversary|bday').hasMatch(lower)
      ? Kind.occasion
      : RegExp(r'meeting|standup|call with|1:1').hasMatch(lower)
          ? Kind.meeting
          : RegExp(r'dinner|lunch|party|dentist|flight|concert').hasMatch(lower)
              ? Kind.event
              : Kind.task;
  var title = rest.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (title.isNotEmpty) title = title[0].toUpperCase() + title.substring(1);
  if (title.isNotEmpty) chips.add(ParsedChip('title', title));
  chips.add(ParsedChip('date', date != null ? _cap(date[0]!) : 'Tomorrow'));
  if (time != null) chips.add(ParsedChip('time', time[0]!.toUpperCase()));
  chips.add(ParsedChip('kind', kind.name[0].toUpperCase() + kind.name.substring(1)));
  if (kind == Kind.occasion) {
    chips.add(const ParsedChip('repeat', 'Every year'));
    chips.add(const ParsedChip('alerts', '1 week, 1 day, on the day'));
  }
  return Parsed(title, when, kind, chips);
}

/// Opens the capture sheet; returns the parsed result when saved.
Future<Parsed?> showCaptureSheet(BuildContext context) {
  final c = AppColors.of(context);
  return showModalBottomSheet<Parsed>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true, // keep buttons clear of the system navigation bar
    backgroundColor: c.surfaceElevated,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.sheet))),
    sheetAnimationStyle: AnimationStyle(curve: const SpringCurve(Springs.snappy, seconds: 0.5), duration: const Duration(milliseconds: 420)),
    builder: (_) => const _CaptureBody(),
  );
}

class _CaptureBody extends StatefulWidget {
  const _CaptureBody();
  @override
  State<_CaptureBody> createState() => _CaptureBodyState();
}

class _CaptureBodyState extends State<_CaptureBody> {
  final _ctl = TextEditingController();
  Timer? _typing;
  Parsed _parsed = stubParse('');

  @override
  void initState() {
    super.initState();
    _ctl.addListener(() => setState(() => _parsed = stubParse(_ctl.text)));
  }

  @override
  void dispose() {
    _typing?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  // Auto-type a fixed phrase so measurements are repeatable (bake-off M1)
  void _demoType() {
    const phrase = "Mom's birthday Oct 12";
    var i = 0;
    _ctl.text = '';
    _typing?.cancel();
    _typing = Timer.periodic(const Duration(milliseconds: 70), (t) {
      i++;
      _ctl.text = phrase.substring(0, i);
      if (i >= phrase.length) t.cancel();
    });
  }

  void _save() {
    if (_parsed.title.isEmpty) return;
    Navigator.of(context).pop(_parsed);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: EdgeInsets.only(left: Space.l, right: Space.l, bottom: MediaQuery.viewInsetsOf(context).bottom + MediaQuery.paddingOf(context).bottom + Space.l),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.42,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _ctl,
              autofocus: false, // parity with RN spike (no auto keyboard)
              onSubmitted: (_) => _save(),
              style: AppText.body.copyWith(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: "Try “Mom's birthday Oct 12”",
                hintStyle: AppText.body.copyWith(color: c.textSecondary),
                filled: true,
                fillColor: c.bgGrouped,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(Radii.row), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
              ),
            ),
            const SizedBox(height: Space.l),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: const SpringCurve(Springs.soft),
              alignment: Alignment.topLeft,
              child: Wrap(
                spacing: Space.s,
                runSpacing: Space.s,
                children: [
                  if (_ctl.text.isNotEmpty)
                    for (var i = 0; i < _parsed.chips.length; i++)
                      _PopIn(
                        key: ValueKey(_parsed.chips[i].key),
                        delay: Duration(milliseconds: i * 60),
                        child: _chip(_parsed.chips[i], c),
                      ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _button('Type demo', c.bgGrouped, c.textPrimary, _demoType),
                const SizedBox(width: Space.s),
                _button('Save', _parsed.title.isNotEmpty ? c.accent : c.separator, Colors.white, _save),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(ParsedChip chip, AppColors c) {
    final isKind = chip.key == 'kind';
    final kc = c.kind[_parsed.kind]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: 6),
      decoration: BoxDecoration(color: isKind ? kc.withValues(alpha: 0.13) : c.bgGrouped, borderRadius: BorderRadius.circular(Radii.chip)),
      child: Text(chip.label, style: AppText.caption.copyWith(color: isKind ? kc : c.textPrimary)),
    );
  }

  Widget _button(String label, Color bg, Color fg, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.m),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(Radii.row)),
          child: Text(label, style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 15, color: fg)),
        ),
      );
}

/// Spring "zoom in" for a newly appearing chip (matches Reanimated ZoomIn.springify()).
class _PopIn extends StatefulWidget {
  final Widget child;
  final Duration delay;
  const _PopIn({super.key, required this.child, required this.delay});
  @override
  State<_PopIn> createState() => _PopInState();
}

class _PopInState extends State<_PopIn> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void initState() {
    super.initState();
    Future.delayed(widget.delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _c, curve: const SpringCurve(Springs.snappy, seconds: 0.45));
    return FadeTransition(opacity: _c, child: ScaleTransition(scale: curved, child: widget.child));
  }
}
