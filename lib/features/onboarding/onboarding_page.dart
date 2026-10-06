/// FL-1 interactive onboarding (design-direction §5): Welcome (notes gather into one list) → Just
/// type it (self-typing demo, then the real parser) → Nudges demo (drag through the week) → Your
/// schedule (nag hours drive a sky) → Calendar → Contact birthdays → Home. Every step after Welcome
/// can be skipped; skipping applies defaults (PRF-11).
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/bell.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../setup/permission_flow.dart';
import '../setup/setup_widgets.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pages = PageController();
  int _step = 0;
  bool _savedFirst = false;
  static const _count = 6;

  void _next() {
    if (_step >= _count - 1) {
      _finish();
      return;
    }
    setState(() => _step++);
    _pages.animateToPage(_step, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic);
  }

  Future<void> _finish() async {
    final s = ref.read(servicesProvider);
    await s.prefs.set(PrefKeys.onboarded, true);
    await s.service.resync();
    if (!mounted) return;
    context.go(_savedFirst ? '/' : '/?capture=1'); // FL-1 step 6
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots + Skip
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: Space.l),
                  for (var i = 0; i < _count; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(right: 6),
                      width: i == _step ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= _step ? c.accent : c.separator,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  const Spacer(),
                  if (_step > 0) TextButton(onPressed: _next, child: Text(l10n.actionSkipStep)),
                  const SizedBox(width: Space.s),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Welcome(onStart: _next),
                  _JustTypeIt(
                    onNext: _next,
                    onSaved: () async {
                      _savedFirst = true;
                      await runPermissionFlowOnce(context); // FL-1 step 7
                      _next();
                    },
                  ),
                  _NudgesDemo(onNext: _next),
                  _YourSchedule(onNext: _next),
                  _Calendar(onNext: _next),
                  _Contacts(onNext: _next),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared layout: illustration area, title, sub, content, primary/secondary buttons.
class _Step extends StatelessWidget {
  const _Step({
    required this.title,
    required this.sub,
    required this.child,
    required this.primary,
    required this.onPrimary,
    this.secondary,
    this.onSecondary,
  });
  final String title;
  final String sub;
  final Widget child;
  final String primary;
  final VoidCallback? onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: Center(child: SingleChildScrollView(child: child))),
          Text(title, style: text.displaySmall?.copyWith(fontSize: 30), textAlign: TextAlign.center),
          const SizedBox(height: Space.s),
          Text(sub, style: text.bodyLarge?.copyWith(color: AppColors.of(context).textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: Space.xl),
          SizedBox(height: 52, child: FilledButton(onPressed: onPrimary, child: Text(primary))),
          SizedBox(
            height: 48,
            child: secondary == null ? null : TextButton(onPressed: onSecondary, child: Text(secondary!)),
          ),
          const SizedBox(height: Space.s),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- S-01 Welcome

class _Welcome extends StatefulWidget {
  const _Welcome({required this.onStart});
  final VoidCallback onStart;

  @override
  State<_Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<_Welcome> with TickerProviderStateMixin {
  late final _drift = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat(reverse: true);
  late final _gather = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

  @override
  void dispose() {
    _drift.dispose();
    _gather.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _gather.forward();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    widget.onStart();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final notes = <(Kind, String, Offset, double)>[
      (Kind.occasion, l10n.obTypeDemo, const Offset(-0.62, -0.75), -0.18),
      (Kind.task, l10n.captureEx2, const Offset(0.55, -0.45), 0.14),
      (Kind.meeting, l10n.captureEx4, const Offset(-0.5, 0.1), 0.1),
      (Kind.event, l10n.captureEx1, const Offset(0.6, 0.45), -0.12),
    ];
    return _Step(
      title: l10n.obWelcomeTitle,
      sub: l10n.obWelcomeSub,
      primary: l10n.actionGetStarted,
      onPrimary: _start,
      child: SizedBox(
        height: 320,
        child: AnimatedBuilder(
          animation: Listenable.merge([_drift, _gather]),
          builder: (context, _) {
            final g = Curves.easeInOutCubic.transform(_gather.value);
            return LayoutBuilder(
              builder: (context, box) => Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(opacity: 1 - g, child: const Bell(size: 96, mood: BellMood.calm)),
                  for (var i = 0; i < notes.length; i++)
                    Builder(builder: (context) {
                      final (kind, label, pos, rot) = notes[i];
                      final wobble = math.sin((_drift.value + i * 0.3) * math.pi) * 6;
                      final scattered = Offset(pos.dx * box.maxWidth / 2, pos.dy * 140 + wobble);
                      final listed = Offset(0, (i - 1.5) * 58);
                      final at = Offset.lerp(scattered, listed, g)!;
                      return Transform.translate(
                        offset: at,
                        child: Transform.rotate(
                          angle: rot * (1 - g),
                          child: Container(
                            width: math.min(260, box.maxWidth * 0.75),
                            padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
                            decoration: BoxDecoration(
                              color: Color.lerp(
                                [const Color(0xFFFFF4B8), const Color(0xFFDFF3FF), const Color(0xFFE8E6FF), const Color(0xFFFFE6D1)][i],
                                c.surface,
                                g,
                              ),
                              borderRadius: BorderRadius.circular(Radii.row),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3))],
                            ),
                            child: Row(
                              children: [
                                Icon(kindIcon(kind), color: c.kind(kind), size: 20),
                                const SizedBox(width: Space.s),
                                Expanded(
                                  child: Text(label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- S-01a Just type it

class _JustTypeIt extends ConsumerStatefulWidget {
  const _JustTypeIt({required this.onNext, required this.onSaved});
  final VoidCallback onNext;
  final Future<void> Function() onSaved;

  @override
  ConsumerState<_JustTypeIt> createState() => _JustTypeItState();
}

class _JustTypeItState extends ConsumerState<_JustTypeIt> {
  final _input = TextEditingController();
  Timer? _typer;
  bool _demo = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDemo());
  }

  void _runDemo() {
    final demo = AppLocalizations.of(context).obTypeDemo;
    var i = 0;
    _typer = Timer.periodic(const Duration(milliseconds: 85), (t) {
      if (!mounted || !_demo) return t.cancel();
      i++;
      _input.text = demo.substring(0, math.min(i, demo.length));
      if (i >= demo.length) t.cancel();
    });
  }

  @override
  void dispose() {
    _typer?.cancel();
    _input.dispose();
    super.dispose();
  }

  ParseResult? get _parsed {
    final t = _input.text.trim();
    if (t.isEmpty) return null;
    final prefs = ref.read(prefsProvider);
    return ReminderParser(ParseContext(
      now: instantToWall(DateTime.now().toUtc(), prefs.defaultTimeZone),
      defaultTimeZone: prefs.defaultTimeZone,
      locale: Localizations.localeOf(context).toLanguageTag(),
      dayTimeHour: prefs.dayTime.hour,
      dayTimeMinute: prefs.dayTime.minute,
    )).parse(t);
  }

  Future<void> _save(ParseResult p) async {
    setState(() => _saving = true);
    final s = ref.read(servicesProvider);
    final r = reminderFromParse(p, meta: await s.reminders.newMeta(), prefs: s.prefs.current, rawInput: _input.text.trim());
    await s.service.create(r);
    await widget.onSaved();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final p = _parsed;
    final chips = p == null
        ? const <(IconData, String, Color)>[]
        : [
            (kindIcon(p.kind), f.kind(p.kind), c.kind(p.kind)),
            if (p.timing != null)
              (Icons.calendar_today_rounded, f.date(parseWall(p.timing!.start)), c.danger),
            if (p.timing?.type == TimingType.datetime)
              (Icons.schedule_rounded, f.time(parseWall(p.timing!.start)), c.accent),
            if (p.rrule != null) (Icons.repeat_rounded, f.repeat(p.rrule, p.repeatMode ?? RecurrenceMode.fixed), c.meeting),
          ];
    final typedDone = _input.text.trim() == l10n.obTypeDemo;
    return _Step(
      title: l10n.obTypeTitle,
      sub: l10n.obTypeSub,
      primary: l10n.actionSaveThis,
      onPrimary: p != null && canSave(p) && !_saving ? () => _save(p) : null,
      secondary: l10n.actionNext,
      onSecondary: widget.onNext,
      child: Column(
        children: [
          Bell(size: 84, mood: typedDone && _demo ? BellMood.happy : BellMood.thinking),
          if (typedDone && _demo)
            Padding(
              padding: const EdgeInsets.only(top: Space.s),
              child: Text(l10n.obBellBirthday, style: Theme.of(context).textTheme.bodyMedium),
            ),
          const SizedBox(height: Space.l),
          Material(
            color: c.surface,
            borderRadius: BorderRadius.circular(Radii.card),
            child: TextField(
              controller: _input,
              readOnly: _demo,
              onTap: () {
                if (_demo) {
                  _typer?.cancel();
                  setState(() => _demo = false);
                  _input.clear();
                }
              },
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: l10n.obTypePlaceholder,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(Space.l),
              ),
            ),
          ),
          const SizedBox(height: Space.m),
          Wrap(
            spacing: Space.s,
            runSpacing: Space.s,
            alignment: WrapAlignment.center,
            children: [
              for (final (i, (icon, label, color)) in chips.indexed)
                TweenAnimationBuilder<double>(
                  key: ValueKey('$i$label'),
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 260 + i * 90),
                  curve: Curves.easeOutBack,
                  builder: (_, v, child) => Transform.scale(scale: v, child: child),
                  child: Chip(
                    avatar: Icon(icon, size: 16, color: color),
                    label: Text(label),
                    backgroundColor: color.withValues(alpha: 0.12),
                    side: BorderSide.none,
                  ),
                ),
            ],
          ),
          if (_demo && typedDone)
            TextButton(
              onPressed: () {
                setState(() => _demo = false);
                _input.clear();
              },
              child: Text(l10n.obTryOwn),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- S-01b Nudges demo

class _NudgesDemo extends StatefulWidget {
  const _NudgesDemo({required this.onNext});
  final VoidCallback onNext;

  @override
  State<_NudgesDemo> createState() => _NudgesDemoState();
}

class _NudgesDemoState extends State<_NudgesDemo> {
  double _day = 0; // 0 = a week before … 7 = the day
  bool _prepared = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final nudges = <(double, String)>[
      (0, l10n.notifBefore(l10n.relWeeks(1), l10n.obTypeDemo.split(' ').skip(2).join(' '))),
      (6, l10n.notifBefore(l10n.relDays(1), l10n.obTypeDemo.split(' ').skip(2).join(' '))),
      (7, l10n.groupToday),
    ];
    final visible = nudges.where((n) => _day >= n.$1 && !(_prepared && n.$1 < 7)).toList();
    return _Step(
      title: l10n.obNudgeTitle,
      sub: l10n.obNudgeSub,
      primary: l10n.actionNext,
      onPrimary: widget.onNext,
      child: Column(
        children: [
          // Phone mockup
          Container(
            width: 230,
            height: 250,
            padding: const EdgeInsets.all(Space.m),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: c.separator, width: 6),
            ),
            child: Column(
              children: [
                for (final (d, body) in visible.reversed)
                  TweenAnimationBuilder<double>(
                    key: ValueKey(d),
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (_, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * -12), child: child)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: Space.s),
                      padding: const EdgeInsets.all(Space.s),
                      decoration: BoxDecoration(color: c.bgGrouped, borderRadius: BorderRadius.circular(Radii.row)),
                      child: Row(
                        children: [
                          const Bell(size: 26, mood: BellMood.calm),
                          const SizedBox(width: Space.s),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n.obTypeDemo.split(' ').take(2).join(' '),
                                    style: text.labelSmall?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700)),
                                Text(body, style: text.labelSmall),
                                if (d < 7 && !_prepared)
                                  GestureDetector(
                                    onTap: () => setState(() => _prepared = true), // OCC-3
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(l10n.actionPrepared,
                                          style: text.labelSmall?.copyWith(color: c.accent, fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          if (_prepared) Text(l10n.obPreparedNote, style: text.bodyMedium?.copyWith(color: c.success)),
          Slider(value: _day, min: 0, max: 7, divisions: 7, onChanged: (v) => setState(() => _day = v)),
          Text(_day < 7 ? l10n.obDragHint : l10n.groupToday, style: text.bodySmall),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- S-02 Your schedule

class _YourSchedule extends ConsumerWidget {
  const _YourSchedule({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final p = ref.watch(prefsProvider);
    final repo = ref.read(servicesProvider).prefs;
    final start = p.nagStart.minutes / 60, end = p.nagEnd.minutes / 60;
    return _Step(
      title: l10n.obScheduleTitle,
      sub: l10n.obScheduleSub,
      primary: l10n.actionLooksGood,
      onPrimary: onNext,
      child: Column(
        children: [
          _Sky(start: start, end: end),
          RangeSlider(
            values: RangeValues(start, end),
            min: 0,
            max: 24,
            divisions: 24,
            labels: RangeLabels(clockText(context, p.nagStart), clockText(context, p.nagEnd)),
            onChanged: (v) {
              if (v.end - v.start < 1) return;
              repo.set(PrefKeys.nagStart, PrefsRepository.encodeTime(ClockTime(v.start.round(), 0)));
              repo.set(PrefKeys.nagEnd, PrefsRepository.encodeTime(ClockTime(math.min(v.end.round(), 23), v.end.round() >= 24 ? 59 : 0)));
            },
          ),
          const ScheduleSettings(),
        ],
      ),
    );
  }
}

/// Sunrise → night sky driven by the nag-hours slider (design-direction §5).
class _Sky extends StatelessWidget {
  const _Sky({required this.start, required this.end});
  final double start;
  final double end;

  static Color _at(double hour) {
    const stops = [
      (0.0, Color(0xFF0B1437)),
      (6.0, Color(0xFFFF9E7A)),
      (9.0, Color(0xFF8CC8FF)),
      (15.0, Color(0xFF5AB0FF)),
      (19.0, Color(0xFFFF8A65)),
      (21.0, Color(0xFF3A2D6B)),
      (24.0, Color(0xFF0B1437)),
    ];
    for (var i = 0; i < stops.length - 1; i++) {
      final (h0, c0) = stops[i];
      final (h1, c1) = stops[i + 1];
      if (hour <= h1) return Color.lerp(c0, c1, (hour - h0) / (h1 - h0))!;
    }
    return stops.last.$2;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 90,
      margin: const EdgeInsets.only(bottom: Space.s),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Radii.card),
        gradient: LinearGradient(colors: [_at(start), _at((start + end) / 2), _at(end)]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: const [
          Padding(padding: EdgeInsets.all(Space.l), child: Icon(Icons.wb_sunny_rounded, color: Colors.white, size: 32)),
          Padding(padding: EdgeInsets.all(Space.l), child: Icon(Icons.nightlight_round, color: Colors.white, size: 28)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- S-03 / S-04 Calendar

class _Calendar extends ConsumerStatefulWidget {
  const _Calendar({required this.onNext});
  final VoidCallback onNext;

  @override
  ConsumerState<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends ConsumerState<_Calendar> {
  bool _picking = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    if (_picking) {
      return _Step(
        title: l10n.obPickCalTitle,
        sub: l10n.obPickCalSub,
        primary: l10n.actionDone,
        onPrimary: widget.onNext,
        child: const CalendarPicker(),
      );
    }
    return _Step(
      title: l10n.obCalTitle,
      sub: l10n.obCalSub,
      primary: l10n.actionConnectCalendar,
      onPrimary: () async {
        final s = ref.read(servicesProvider);
        final ok = await s.calendar.connect();
        if (ok && s.calendar.calendars.isNotEmpty) {
          setState(() => _picking = true);
        } else {
          widget.onNext(); // PRM-3: denied → continue; Settings can enable it later
        }
      },
      secondary: l10n.actionNotNow,
      onSecondary: widget.onNext,
      child: Column(
        children: [
          for (final (i, k) in [Kind.meeting, Kind.event, Kind.occasion].indexed)
            Container(
              width: 240,
              margin: EdgeInsets.only(left: i * 24.0, bottom: Space.s),
              padding: const EdgeInsets.all(Space.m),
              decoration: BoxDecoration(
                color: c.kind(k).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(Radii.row),
                border: Border(left: BorderSide(color: c.kind(k), width: 3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 16, color: c.kind(k)),
                  const SizedBox(width: Space.s),
                  Text(Fmt.of(context).kind(k)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- S-08 Contact birthdays

class _Contacts extends ConsumerWidget {
  const _Contacts({required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return _Step(
      title: l10n.obContactsTitle,
      sub: l10n.obContactsSub,
      primary: l10n.actionAddBirthdays,
      onPrimary: () async {
        final n = await showContactsReview(context, ref); // CON-1, CON-3, PRM-8
        if (!context.mounted) return;
        if ((n ?? 0) > 0) {
          await showAppSheet<void>(
            context,
            (ctx) => Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Bell(size: 120, mood: BellMood.party),
                  const SizedBox(height: Space.m),
                  Text(l10n.obBellParty, style: Theme.of(ctx).textTheme.titleMedium),
                  const SizedBox(height: Space.l),
                  FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionContinue)),
                ],
              ),
            ),
          );
        }
        onNext();
      },
      secondary: l10n.actionNotNow,
      onSecondary: onNext,
      child: const Bell(size: 150, mood: BellMood.happy),
    );
  }
}
