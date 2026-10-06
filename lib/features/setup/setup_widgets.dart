/// Setup pieces shared by onboarding and Settings: "Your schedule" (S-02 / S-51), the test reminder
/// (PRM-7), calendar picking (S-04 / S-55) and the contacts birthday review (S-08 / CON-3).
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reminder_core/reminder_core.dart';

import '../../app/providers.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/format.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../pickers/pickers.dart';

Future<ClockTime?> pickClockTime(BuildContext context, ClockTime current) async {
  final t = await showTimePicker(context: context, initialTime: TimeOfDay(hour: current.hour, minute: current.minute));
  return t == null ? null : ClockTime(t.hour, t.minute);
}

String clockText(BuildContext context, ClockTime t) => Fmt.of(context).time(DateTime.utc(2026, 1, 1, t.hour, t.minute));

/// S-02 / S-51 rows: time zone, day time (PRF-3), nag hours (PRF-4), "Tomorrow" means (PRF-5).
class ScheduleSettings extends ConsumerWidget {
  const ScheduleSettings({super.key, this.onZoneTap});

  /// Settings opens the full S-52 flow; onboarding just picks the zone.
  final VoidCallback? onZoneTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final p = ref.watch(prefsProvider);
    final repo = ref.read(servicesProvider).prefs;
    final s = ref.read(servicesProvider).service;
    Future<void> save(String key, Object? v) async {
      await repo.set(key, v);
      await s.resync(); // PRF-10
    }

    return InsetGroup(
      indent: 56,
      children: [
        FormRow(
          icon: Icons.public_rounded,
          color: c.meeting,
          label: l10n.rowTimeZone,
          value: Fmt.city(p.defaultTimeZone),
          onTap: onZoneTap ??
              () async {
                final z = await pickTimeZone(context, p.defaultTimeZone);
                if (z != null) await save(PrefKeys.defaultTimeZone, z);
              },
        ),
        FormRow(
          icon: Icons.wb_sunny_outlined,
          color: c.event,
          label: l10n.rowDateOnlyAt,
          subtitle: l10n.rowDateOnlyAtSub,
          value: clockText(context, p.dayTime),
          onTap: () async {
            final t = await pickClockTime(context, p.dayTime);
            if (t != null) await save(PrefKeys.dayTime, PrefsRepository.encodeTime(t));
          },
        ),
        FormRow(
          icon: Icons.replay_rounded,
          color: c.success,
          label: l10n.rowNagHours,
          subtitle: l10n.rowNagHoursSub,
          value: l10n.timeRange(clockText(context, p.nagStart), clockText(context, p.nagEnd)),
          onTap: () async {
            final a = await pickClockTime(context, p.nagStart);
            if (a == null || !context.mounted) return;
            final b = await pickClockTime(context, p.nagEnd);
            if (b == null) return;
            await repo.set(PrefKeys.nagStart, PrefsRepository.encodeTime(a));
            await save(PrefKeys.nagEnd, PrefsRepository.encodeTime(b));
          },
        ),
        FormRow(
          icon: Icons.snooze_rounded,
          color: c.accent,
          label: l10n.rowTomorrowMeans,
          value: p.tomorrowMode == TomorrowMode.dayTime
              ? l10n.tomorrowAtTime(clockText(context, p.dayTime))
              : l10n.tomorrowSameTime,
          onTap: () => save(
            PrefKeys.tomorrowMode,
            (p.tomorrowMode == TomorrowMode.dayTime ? TomorrowMode.sameTime : TomorrowMode.dayTime).name,
          ),
        ),
      ],
    );
  }
}

enum TestState { idle, waiting, ok, late, failed }

/// PRM-7 Send test reminder: 15 s ahead through the normal path; checks the native fire log.
class TestReminderPanel extends ConsumerStatefulWidget {
  const TestReminderPanel({super.key, this.compact = false});
  final bool compact;

  @override
  ConsumerState<TestReminderPanel> createState() => _TestReminderPanelState();
}

class _TestReminderPanelState extends ConsumerState<TestReminderPanel> with WidgetsBindingObserver {
  TestState _state = TestState.idle;
  int _lateSeconds = 0;
  DateTime? _sentAt;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed && _state == TestState.waiting) _check();
  }

  Future<void> _send() async {
    final s = ref.read(servicesProvider);
    final l10n = AppLocalizations.of(context);
    _sentAt = await s.service.sendTestReminder(title: l10n.testNotifTitle, body: l10n.testNotifBody);
    setState(() => _state = TestState.waiting);
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 3), (_) => _check());
  }

  Future<void> _check() async {
    final sent = _sentAt;
    if (sent == null) return;
    final s = ref.read(servicesProvider);
    final log = await s.alarms.fireLog(sent.subtract(const Duration(seconds: 1)));
    final hit = log.where((f) => f.alarmKey.startsWith('test~${sent.millisecondsSinceEpoch}')).firstOrNull;
    if (hit != null) {
      final late = hit.delay.inSeconds;
      _finish(hit.outcome == 'missed' ? TestState.failed : (late <= 60 ? TestState.ok : TestState.late), late);
    } else if (DateTime.now().toUtc().difference(sent) > const Duration(minutes: 2)) {
      _finish(TestState.failed, 0);
    }
  }

  void _finish(TestState st, int late) {
    _poll?.cancel();
    if (!mounted) return;
    setState(() {
      _state = st;
      _lateSeconds = late;
    });
    ref.read(servicesProvider).prefs.set(PrefKeys.lastTest, '${st.name}:$late');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    final perms = ref.watch(permissionsProvider);
    final (icon, color, title, sub) = switch (_state) {
      TestState.idle => (Icons.notifications_active_outlined, c.accent, l10n.testTitle, l10n.testSub),
      TestState.waiting => (Icons.hourglass_top_rounded, c.accent, l10n.testWaiting, l10n.testSub),
      TestState.ok => (Icons.check_circle_rounded, c.success, l10n.testOk, null),
      TestState.late => (
          Icons.warning_amber_rounded,
          c.warning,
          l10n.testLate(_lateSeconds),
          !perms.exactAlarms ? l10n.testFixExact : l10n.testFixBattery,
        ),
      TestState.failed => (Icons.error_outline_rounded, c.danger, l10n.testFail, l10n.testSteps),
    };
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(Radii.card),
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: Space.s),
                Expanded(child: Text(title, style: text.titleMedium)),
                if (_state == TestState.waiting) const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
              ],
            ),
            if (sub != null) ...[const SizedBox(height: Space.xs), Text(sub, style: text.bodyMedium)],
            if (_state == TestState.late || _state == TestState.failed) ...[
              const SizedBox(height: Space.s),
              Wrap(
                spacing: Space.s,
                children: [
                  if (!perms.notifications)
                    OutlinedButton(
                      onPressed: ref.read(servicesProvider).alarms.requestNotificationPermission,
                      child: Text(l10n.relNotifications),
                    ),
                  if (!perms.exactAlarms)
                    OutlinedButton(
                      onPressed: ref.read(servicesProvider).alarms.openExactAlarmSettings,
                      child: Text(l10n.relPrecise),
                    ),
                  if (!perms.batteryUnrestricted)
                    OutlinedButton(
                      onPressed: ref.read(servicesProvider).alarms.openBatteryOptimizationSettings,
                      child: Text(l10n.relBattery),
                    ),
                ],
              ),
            ],
            if (_state != TestState.waiting) ...[
              const SizedBox(height: Space.m),
              FilledButton.tonalIcon(
                onPressed: _send,
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text(l10n.actionSendTest),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// S-04 / S-55: device calendars with color and toggle (CAL-1).
class CalendarPicker extends ConsumerStatefulWidget {
  const CalendarPicker({super.key});

  @override
  ConsumerState<CalendarPicker> createState() => _CalendarPickerState();
}

class _CalendarPickerState extends ConsumerState<CalendarPicker> {
  @override
  Widget build(BuildContext context) {
    final cal = ref.read(servicesProvider).calendar;
    ref.watch(calendarRemindersProvider);
    final selected = cal.selected;
    return InsetGroup(
      indent: Space.l,
      children: [
        for (final c in cal.calendars)
          CheckboxListTile(
            value: selected.contains(c.id),
            activeColor: Color(c.color | 0xFF000000),
            secondary: Icon(Icons.circle, size: 16, color: Color(c.color | 0xFF000000)),
            title: Text(c.name),
            subtitle: Text(c.accountName),
            onChanged: (v) async {
              final next = {...selected};
              v! ? next.add(c.id) : next.remove(c.id);
              await cal.setSelected(next);
              await ref.read(servicesProvider).service.resync();
              setState(() {});
            },
          ),
      ],
    );
  }
}

/// S-08 / CON-3: review list of contact birthdays and anniversaries, all selected, then Import.
Future<int?> showContactsReview(BuildContext context, WidgetRef ref) async {
  final s = ref.read(servicesProvider);
  final found = await s.contacts.preview();
  if (!context.mounted) return null;
  return showAppSheet<int>(context, (ctx) => _ContactsReview(found: found), expand: true);
}

class _ContactsReview extends ConsumerStatefulWidget {
  const _ContactsReview({required this.found});
  final List<ContactDate> found;

  @override
  ConsumerState<_ContactsReview> createState() => _ContactsReviewState();
}

class _ContactsReviewState extends ConsumerState<_ContactsReview> {
  late final Set<String> _chosen = {for (final c in widget.found) c.key};
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final f = Fmt.of(context);
    final c = AppColors.of(context);
    final birthdays = widget.found.where((x) => x.field == ContactDateField.birthday).length;
    return Column(
      children: [
        SheetBar(
          title: l10n.contactsBirthdays,
          left: TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.actionCancel)),
          right: TextButton(
            onPressed: _busy || _chosen.isEmpty
                ? null
                : () async {
                    setState(() => _busy = true);
                    final n = await ref
                        .read(servicesProvider)
                        .contacts
                        .importSelected(widget.found.where((x) => _chosen.contains(x.key)).toList());
                    if (context.mounted) Navigator.pop(context, n);
                  },
            child: Text(l10n.actionImport),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.s),
          child: Text(l10n.contactsFound(birthdays, widget.found.length - birthdays)),
        ),
        Expanded(
          child: ListView(
            children: [
              for (final x in widget.found)
                CheckboxListTile(
                  value: _chosen.contains(x.key),
                  secondary: Icon(
                    x.field == ContactDateField.birthday ? Icons.cake_outlined : Icons.favorite_border_rounded,
                    color: c.occasion,
                  ),
                  title: Text(contactTitle(x)),
                  subtitle: Text(f.date(DateTime.utc(2026, x.month, x.day)).replaceAll(RegExp(r'^\w+, '), '')),
                  onChanged: (v) => setState(() => v! ? _chosen.add(x.key) : _chosen.remove(x.key)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
