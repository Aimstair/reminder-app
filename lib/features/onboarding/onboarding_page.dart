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
import '../../ui/icons.dart';
import '../../ui/motion.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.replay = false});

  /// Opened from Settings → Replay intro (S-58): ends back in Settings, never opens capture.
  final bool replay;

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
    if (widget.replay) {
      context.pop();
      return;
    }
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
      backgroundColor: c.surface, // white like mockup 01
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
    this.below,
  });
  final String title;
  final String sub;
  final Widget child;
  final String primary;
  final VoidCallback? onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;

  /// Shown under the title and text (the "Try your own" card on S-01a).
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final c = AppColors.of(context);
    final primaryButton = SizedBox(
      height: 56,
      child: FilledButton(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card + 4)),
        ),
        onPressed: onPrimary,
        child: Text(primary),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(child: SingleChildScrollView(child: child)),
          ),
          // Left-aligned, large (mockup 01).
          Text(title, style: text.displaySmall?.copyWith(fontSize: 34)),
          const SizedBox(height: Space.s),
          Text(
            sub,
            style: text.titleMedium?.copyWith(color: c.textSecondary, fontWeight: FontWeight.w400),
          ),
          if (below != null) ...[const SizedBox(height: Space.l), below!],
          const SizedBox(height: Space.xl),
          if (secondary == null)
            primaryButton
          else
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: c.separator.withValues(alpha: 0.18),
                        foregroundColor: c.textPrimary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.card + 4)),
                      ),
                      onPressed: onSecondary,
                      child: Text(secondary!),
                    ),
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(flex: 2, child: primaryButton),
              ],
            ),
          const SizedBox(height: Space.m),
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
                  Opacity(
                    opacity: 1 - g,
                    child: const Bell(size: 96, mood: BellMood.calm),
                  ),
                  for (var i = 0; i < notes.length; i++)
                    Builder(
                      builder: (context) {
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
                                  [
                                    const Color(0xFFFFF4B8),
                                    const Color(0xFFDFF3FF),
                                    const Color(0xFFE8E6FF),
                                    const Color(0xFFFFE6D1),
                                  ][i],
                                  c.surface,
                                  g,
                                ),
                                borderRadius: BorderRadius.circular(Radii.row),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(kindIcon(kind), color: c.kind(kind), size: 20),
                                  const SizedBox(width: Space.s),
                                  Expanded(
                                    child: Text(
                                      label,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
    return ReminderParser(
      ParseContext(
        now: instantToWall(DateTime.now().toUtc(), prefs.defaultTimeZone),
        defaultTimeZone: prefs.defaultTimeZone,
        locale: Localizations.localeOf(context).toLanguageTag(),
        dayTimeHour: prefs.dayTime.hour,
        dayTimeMinute: prefs.dayTime.minute,
      ),
    ).parse(t);
  }

  Future<void> _save(ParseResult p) async {
    setState(() => _saving = true);
    final s = ref.read(servicesProvider);
    final r = reminderFromParse(
      p,
      meta: await s.reminders.newMeta(),
      prefs: s.prefs.current,
      rawInput: _input.text.trim(),
    );
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
            if (p.timing != null) (AppIcons.calendar, f.date(parseWall(p.timing!.start)), c.danger),
            if (p.timing?.type == TimingType.datetime) (AppIcons.time, f.time(parseWall(p.timing!.start)), c.accent),
            if (p.rrule != null) (AppIcons.repeat, f.repeat(p.rrule, p.repeatMode ?? RecurrenceMode.fixed), c.meeting),
          ];
    final typedDone = _input.text.trim() == l10n.obTypeDemo;
    final text = Theme.of(context).textTheme;
    final alerts = p == null ? null : _alertsChip(f, p);
    return _Step(
      title: l10n.obTypeTitle,
      sub: l10n.obTypeSub,
      primary: l10n.actionSaveThis,
      onPrimary: p != null && canSave(p) && !_saving ? () => _save(p) : null,
      secondary: l10n.actionNext,
      onSecondary: widget.onNext,
      // Bell surrounded by example cards (mockup 01). Arguments follow the screen: art, then `below`.
      // ignore: sort_child_properties_last
      child: SizedBox(
        height: 300,
        child: LayoutBuilder(
          builder: (context, box) => Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(color: c.event.withValues(alpha: 0.10), shape: BoxShape.circle),
              ),
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(color: c.event.withValues(alpha: 0.14), shape: BoxShape.circle),
              ),
              Bell(size: 150, mood: typedDone && _demo ? BellMood.happy : BellMood.calm),
              _FloatCard(
                left: 0,
                top: 4,
                angle: -0.06,
                icon: AppIcons.gift,
                color: c.occasion,
                title: l10n.obCard1Title,
                sub: l10n.obCard1Sub,
              ),
              _FloatCard(
                right: 0,
                top: 70,
                angle: 0.06,
                icon: AppIcons.bill,
                color: c.event,
                title: l10n.obCard2Title,
                sub: l10n.obCard2Sub,
              ),
              _FloatCard(
                left: 8,
                bottom: 40,
                angle: 0.04,
                icon: AppIcons.video,
                color: c.meeting,
                title: l10n.obCard3Title,
                sub: l10n.obCard3Sub,
              ),
              _FloatCard(
                right: 12,
                bottom: 0,
                angle: -0.06,
                icon: AppIcons.bag,
                color: c.task,
                title: l10n.obCard4Title,
                sub: l10n.obCard4Sub,
              ),
            ],
          ),
        ),
      ),
      below: Container(
        padding: const EdgeInsets.all(Space.l),
        decoration: BoxDecoration(
          color: c.separator.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(Radii.sheet),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.obTryOwn,
              style: text.titleSmall?.copyWith(color: c.textSecondary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: Space.s),
            Container(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(Radii.card),
                border: Border.all(color: c.accent, width: 2),
              ),
              child: Row(
                children: [
                  Expanded(
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
                      style: text.bodyLarge,
                      decoration: InputDecoration(
                        hintText: l10n.obTypePlaceholder,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: Space.s),
                    child: IconButton.filledTonal(
                      style: IconButton.styleFrom(backgroundColor: c.accent.withValues(alpha: 0.12)),
                      onPressed: null,
                      icon: Icon(AppIcons.mic, color: c.accent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.m),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final (i, (icon, label, color, tinted)) in [
                  ...chips.map((x) => (x.$1, x.$2, x.$3, x == chips.first)),
                  if (alerts != null) (AppIcons.alert, alerts, c.textPrimary, false),
                ].indexed)
                  TweenAnimationBuilder<double>(
                    key: ValueKey('$i$label'),
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 260 + i * 90),
                    curve: Curves.easeOutBack,
                    builder: (_, v, child) => Transform.scale(scale: v, child: child),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
                      decoration: BoxDecoration(
                        color: tinted ? color.withValues(alpha: 0.14) : c.surface,
                        borderRadius: BorderRadius.circular(Radii.row),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 16, color: tinted ? color : c.textPrimary),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: text.titleSmall?.copyWith(
                              color: tinted ? color : c.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// "1 week · 1 day · on the day" (mockup 01): the alert plan without "before".
  String _alertsChip(Fmt f, ParseResult p) {
    final allDay = p.timing?.type != TimingType.datetime;
    final plan =
        p.alerts?.map((o) => AlertStage(AlertOffset.parse(o))).toList() ??
        ref.read(prefsProvider).alertPlanFor(p.kind, p.timing?.type ?? TimingType.date);
    return plan
        .map((s) {
          final o = s.offset;
          if (o.amount == 0) return f.offset(o, allDay: allDay);
          return f.offset(AlertOffset(o.amount.abs(), o.unit), allDay: allDay); // positive → no "before"
        })
        .join(' · ');
  }
}

/// Floating example card around the bell (mockup 01).
class _FloatCard extends StatelessWidget {
  const _FloatCard({
    this.left,
    this.right,
    this.top,
    this.bottom,
    required this.angle,
    required this.icon,
    required this.color,
    required this.title,
    required this.sub,
  });
  final double? left, right, top, bottom;
  final double angle;
  final IconData icon;
  final Color color;
  final String title;
  final String sub;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Floating(
        amplitude: 5,
        phase: (angle.abs() * 7) % 1, // cards drift out of sync
        period: Duration(milliseconds: 2600 + (angle.abs() * 8000).round()),
        child: Transform.rotate(
          angle: angle,
          child: Container(
            padding: const EdgeInsets.fromLTRB(Space.s, Space.s, Space.l, Space.s),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(Radii.card),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 14, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconTile(icon: icon, color: color, size: 34),
                const SizedBox(width: Space.s),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                    Text(sub, style: text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
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
                    builder: (_, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(offset: Offset(0, (1 - v) * -12), child: child),
                    ),
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
                                Text(
                                  l10n.obTypeDemo.split(' ').take(2).join(' '),
                                  style: text.labelSmall?.copyWith(color: c.textPrimary, fontWeight: FontWeight.w700),
                                ),
                                Text(body, style: text.labelSmall),
                                if (d < 7 && !_prepared)
                                  GestureDetector(
                                    onTap: () => setState(() => _prepared = true), // OCC-3
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        l10n.actionPrepared,
                                        style: text.labelSmall?.copyWith(color: c.accent, fontWeight: FontWeight.w700),
                                      ),
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
              repo.set(
                PrefKeys.nagEnd,
                PrefsRepository.encodeTime(ClockTime(math.min(v.end.round(), 23), v.end.round() >= 24 ? 59 : 0)),
              );
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
          Padding(
            padding: EdgeInsets.all(Space.l),
            child: Icon(AppIcons.sun, color: Colors.white, size: 32),
          ),
          Padding(
            padding: EdgeInsets.all(Space.l),
            child: Icon(AppIcons.night, color: Colors.white, size: 28),
          ),
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
                  Icon(AppIcons.calendar, size: 16, color: c.kind(k)),
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
