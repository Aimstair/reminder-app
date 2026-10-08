/// S-50 Settings home and S-51…S-58 sub-screens (copy.md §8). Changing a setting rebuilds future
/// alerts only (PRF-10).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder_core/reminder_core.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/version.dart';
import '../../data/prefs_repository.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ui/art.dart';
import '../../ui/bell.dart';
import '../../ui/format.dart';
import '../../ui/motion.dart';
import '../../ui/tokens.dart';
import '../../ui/widgets.dart';
import '../pickers/pickers.dart';
import '../setup/setup_widgets.dart';
import '../../ui/icons.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final rows = <(String, IconData, Color, String)>[
      (l10n.secSchedule, AppIcons.day, c.event, 'schedule'),
      (l10n.secTimeZone, AppIcons.timeZone, c.meeting, 'timezone'),
      (l10n.secDefaultAlerts, AppIcons.alerts, c.warning, 'alerts'),
      (l10n.secNotifications, AppIcons.digest, c.danger, 'notifications'),
      (l10n.secCalendars, AppIcons.calendar, c.accent, 'calendars'),
      (l10n.secViews, AppIcons.appearance, c.occasion, 'views'),
      (l10n.secReliability, AppIcons.reliability, c.success, 'reliability'),
      (l10n.secBackup, AppIcons.backup, c.textSecondary, 'about'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(top: Space.s, bottom: Space.xxxl),
        children: [
          const FadeSlideIn(child: _SettingsHeader()),
          const SizedBox(height: Space.xxl),
          FadeSlideIn(
            index: 1,
            child: InsetGroup(
              indent: 56,
              children: [
                for (final (label, icon, color, path) in rows.take(4))
                  FormRow(label: label, icon: icon, color: color, onTap: () => context.push('/settings/$path')),
              ],
            ),
          ),
          const SizedBox(height: Space.xxl),
          FadeSlideIn(
            index: 2,
            child: InsetGroup(
              indent: 56,
              children: [
                for (final (label, icon, color, path) in rows.skip(4))
                  FormRow(label: label, icon: icon, color: color, onTap: () => context.push('/settings/$path')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Apple-ID-style card at the top of Settings: the bell, the app name and the privacy line.
class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final text = Theme.of(context).textTheme;
    return Container(
      height: 88,
      margin: const EdgeInsets.symmetric(horizontal: Space.l),
      padding: const EdgeInsets.symmetric(horizontal: Space.l),
      decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(Radii.row)),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [c.accent.withValues(alpha: 0.18), c.purple.withValues(alpha: 0.22)],
              ),
            ),
            child: const Center(
              child: Floating(amplitude: 2, child: Bell(size: 44, mood: BellMood.happy)),
            ),
          ),
          const SizedBox(width: Space.m + 2),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.appName, style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(l10n.settingsHeaderSub, style: text.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Icon(AppIcons.privacy, color: c.success, size: 22),
        ],
      ),
    );
  }
}

/// Scaffold for a settings sub-screen: a page hero (DS15) with the section's icon and one line,
/// then the groups, sliding in one after another.
class _Sub extends StatelessWidget {
  const _Sub({required this.title, required this.children, required this.icon, required this.color, this.caption});
  final String title;
  final List<Widget> children;
  final IconData icon;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.only(bottom: Space.xxxl),
      children: [
        PageHero(icon: icon, color: color, caption: caption),
        const SizedBox(height: Space.s),
        for (var i = 0; i < children.length; i++) FadeSlideIn(index: i + 1, child: children[i]),
      ],
    ),
  );
}

class _Desc extends StatelessWidget {
  const _Desc(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.xl, Space.s, Space.xl, 0),
    child: Text(text, style: Theme.of(context).textTheme.bodySmall),
  );
}

/// S-51 Your schedule (same fields as S-02).
class ScheduleSettingsPage extends StatelessWidget {
  const ScheduleSettingsPage({super.key});

  @override
  Widget build(BuildContext context) => _Sub(
    title: AppLocalizations.of(context).secSchedule,
    icon: AppIcons.day,
    color: AppColors.of(context).event,
    caption: AppLocalizations.of(context).heroSchedule,
    children: [ScheduleSettings(onZoneTap: () => context.push('/settings/timezone'))],
  );
}

/// S-52 Time zone: default zone (TIM-7 change dialog) and travel prompt (PRF-2).
class TimeZoneSettingsPage extends ConsumerWidget {
  const TimeZoneSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final p = ref.watch(prefsProvider);
    final s = ref.read(servicesProvider);
    return _Sub(
      title: l10n.secTimeZone,
      icon: AppIcons.timeZone,
      color: c.meeting,
      caption: l10n.heroTimeZone,
      children: [
        InsetGroup(
          indent: 56,
          children: [
            FormRow(
              icon: AppIcons.timeZone,
              color: c.meeting,
              label: l10n.setDefaultZone,
              value: Fmt.city(p.defaultTimeZone),
              onTap: () => changeDefaultZone(context, ref),
            ),
            SwitchRow(
              icon: AppIcons.travel,
              color: c.accent,
              label: l10n.setAskTravel,
              value: p.askOnTravel,
              onChanged: (v) => s.prefs.set(PrefKeys.askOnTravel, v),
            ),
          ],
        ),
        _Desc('${l10n.setDefaultZoneDesc} ${l10n.setAskTravelDesc}'),
      ],
    );
  }
}

/// FL-16 / TIM-7: pick a zone, then "Only new reminders" / "Also move upcoming reminders".
Future<void> changeDefaultZone(BuildContext context, WidgetRef ref) async {
  final s = ref.read(servicesProvider);
  final old = s.prefs.current.defaultTimeZone;
  final zone = await pickTimeZone(context, old);
  if (zone == null || zone == old || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final upcoming = await s.service.upcomingInZone(old);
  if (!context.mounted) return;
  var move = false;
  if (upcoming.isNotEmpty) {
    final choice = await showDialog<bool>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.zoneDialogTitle),
        children: [
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.zoneOnlyNew)),
          SimpleDialogOption(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.zoneMoveUpcoming)),
        ],
      ),
    );
    if (choice == null || !context.mounted) return;
    if (choice) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.zoneConfirm(upcoming.length, Fmt.city(zone))),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.actionConfirm)),
          ],
        ),
      );
      if (ok != true) return;
      move = true;
    }
  }
  await s.prefs.set(PrefKeys.defaultTimeZone, zone);
  if (move) {
    await s.service.moveUpcomingToZone(old, zone);
  } else {
    await s.service.resync();
  }
}

/// S-53 Default alerts per type (PRF-9).
class AlertDefaultsPage extends ConsumerWidget {
  const AlertDefaultsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final f = Fmt.of(context);
    final p = ref.watch(prefsProvider);
    final repo = ref.read(servicesProvider).prefs;
    return _Sub(
      title: l10n.secDefaultAlerts,
      icon: AppIcons.alerts,
      color: c.warning,
      caption: l10n.setDefaultAlertsDesc,
      children: [
        InsetGroup(
          indent: 56,
          children: [
            for (final k in Kind.values)
              FormRow(
                icon: kindIcon(k),
                color: c.kind(k),
                label: f.kind(k),
                value: f.alerts(p.alertPlanFor(k, k == Kind.occasion ? TimingType.date : TimingType.datetime)),
                onTap: () async {
                  final plan = await pickAlerts(
                    context,
                    p.alertPlanFor(k, k == Kind.occasion ? TimingType.date : TimingType.datetime),
                  );
                  if (plan != null) await repo.setAlertDefault(k, plan);
                },
                trailing: p.alertDefaults.containsKey(k)
                    ? TextButton(onPressed: () => repo.setAlertDefault(k, null), child: Text(l10n.resetDefault))
                    : null,
              ),
          ],
        ),
      ],
    );
  }
}

/// S-54 Notifications & digest: digest time (PRF-7), digest notification (PRF-8), late alerts (PRF-6).
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final p = ref.watch(prefsProvider);
    final s = ref.read(servicesProvider);
    Future<void> save(String k, Object? v) async {
      await s.prefs.set(k, v);
      await s.service.resync();
    }

    final cutoffs = <(String, int?)>[
      (l10n.late30m, 30),
      (l10n.late2h, 120),
      (l10n.late6h, 360),
      (l10n.lateAlways, null),
    ];
    final current = p.lateAlertCutoff?.inMinutes;
    return _Sub(
      title: l10n.secNotifications,
      icon: AppIcons.digest,
      color: c.danger,
      caption: l10n.heroNotifications,
      children: [
        InsetGroup(
          indent: 56,
          children: [
            FormRow(
              icon: AppIcons.digest,
              color: c.warning,
              label: l10n.setDigestTime,
              subtitle: l10n.setDigestTimeDesc,
              value: clockText(context, p.digestTime),
              onTap: () async {
                final t = await pickClockTime(context, p.digestTime);
                if (t != null) await save(PrefKeys.digestTime, PrefsRepository.encodeTime(t));
              },
            ),
            SwitchRow(
              icon: AppIcons.notifications,
              color: c.danger,
              label: l10n.setDigestNotif,
              subtitle: l10n.setDigestNotifDesc,
              value: p.digestNotification,
              onChanged: (v) => save(PrefKeys.digestNotification, v),
            ),
          ],
        ),
        GroupCaption(l10n.setLateAlerts),
        InsetGroup(
          indent: 56,
          children: [
            for (final (i, (label, mins)) in cutoffs.indexed)
              ChoiceRow(
                icon: [AppIcons.precise, AppIcons.waiting, AppIcons.evening, AppIcons.alerts][i],
                color: [c.accent, c.meeting, c.purple, c.warning][i],
                label: label,
                selected: current == mins,
                onTap: () => save(PrefKeys.lateAlertCutoffMin, mins),
              ),
          ],
        ),
        _Desc(l10n.setLateAlertsDesc),
      ],
    );
  }
}

/// S-55 Calendars & contacts.
class CalendarSettingsPage extends ConsumerStatefulWidget {
  const CalendarSettingsPage({super.key});

  @override
  ConsumerState<CalendarSettingsPage> createState() => _CalendarSettingsPageState();
}

class _CalendarSettingsPageState extends ConsumerState<CalendarSettingsPage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final s = ref.read(servicesProvider);
    ref.watch(calendarRemindersProvider);
    ref.watch(prefsTickProvider);
    final cal = s.calendar;
    final connected = cal.connected && cal.permission;
    return _Sub(
      title: l10n.secCalendars,
      icon: AppIcons.calendar,
      color: c.accent,
      caption: l10n.heroCalendars,
      children: [
        InsetGroup(
          indent: 56,
          children: [
            if (!connected)
              FormRow(
                icon: AppIcons.calendar,
                color: c.accent,
                label: l10n.actionConnectCalendar,
                subtitle: cal.connected ? l10n.calPermissionOff : null,
                onTap: () async {
                  if (await cal.connect()) await s.service.resync();
                  setState(() {});
                },
              )
            else
              FormRow(
                icon: AppIcons.disconnect,
                color: c.danger,
                label: l10n.calDisconnect,
                destructive: true,
                onTap: () async {
                  await cal.disconnect();
                  await s.service.resync();
                  setState(() {});
                },
              ),
          ],
        ),
        if (connected) ...[GroupCaption(l10n.drawerCalendars), const CalendarPicker()],
        GroupCaption(l10n.contactsBirthdays),
        InsetGroup(
          indent: 56,
          children: [
            SwitchRow(
              icon: AppIcons.birthday,
              color: c.occasion,
              label: l10n.contactsBirthdays,
              value: s.contacts.enabled,
              onChanged: (v) async {
                if (v) {
                  await showContactsReview(context, ref);
                } else {
                  await s.contacts.disable();
                }
                if (mounted) setState(() {});
              },
            ),
            if (s.contacts.enabled) ...[
              SwitchRow(
                icon: AppIcons.autoAdd,
                color: c.success,
                label: l10n.setAutoAdd,
                subtitle: l10n.setAutoAddDesc,
                value: ref.watch(prefsProvider).autoAddBirthdays,
                onChanged: (v) => s.prefs.set(PrefKeys.autoAddBirthdays, v),
              ),
              FormRow(
                icon: AppIcons.review,
                color: c.accent,
                label: l10n.contactsReview,
                onTap: () => showContactsReview(context, ref),
              ),
            ],
          ],
        ),
        _Desc(l10n.obContactsSub),
      ],
    );
  }
}

/// S-56 Views & appearance: start in (VW-1), show completed (VW-6), theme, sounds (PRF-12).
class ViewSettingsPage extends ConsumerWidget {
  const ViewSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final repo = ref.watch(prefsRepoProvider);
    final p = ref.watch(prefsProvider);
    final startIn = repo.string(PrefKeys.startIn) ?? 'last';
    final theme = repo.string(PrefKeys.theme) ?? 'system';
    return _Sub(
      title: l10n.secViews,
      icon: AppIcons.appearance,
      color: c.occasion,
      caption: l10n.heroViews,
      children: [
        GroupCaption(l10n.setTheme),
        PreviewChoices<String>(
          selected: theme,
          onChanged: (v) => repo.set(PrefKeys.theme, v),
          items: [
            (value: 'system', label: l10n.themeSystem, preview: const MiniScreen.system()),
            (value: 'light', label: l10n.themeLight, preview: const MiniScreen.light()),
            (value: 'dark', label: l10n.themeDark, preview: const MiniScreen.dark()),
          ],
        ),
        GroupCaption(l10n.setStartIn),
        PreviewChoices<String>(
          selected: startIn,
          onChanged: (v) => repo.set(PrefKeys.startIn, v),
          items: [
            (value: 'last', label: l10n.startLast, preview: const MiniView.last()),
            (value: 'schedule', label: l10n.viewSchedule, preview: const MiniView.schedule()),
            (value: 'day', label: l10n.viewDay, preview: const MiniView.day()),
            (value: 'month', label: l10n.viewMonth, preview: const MiniView.month()),
          ],
        ),
        const SizedBox(height: Space.xxl),
        InsetGroup(
          indent: 56,
          children: [
            SwitchRow(
              icon: AppIcons.done,
              color: c.success,
              label: l10n.setShowCompleted,
              value: repo.flag(PrefKeys.showCompleted, fallback: true),
              onChanged: (v) => repo.set(PrefKeys.showCompleted, v),
            ),
            SwitchRow(
              icon: AppIcons.sound,
              color: c.occasion,
              label: l10n.setSounds,
              subtitle: l10n.setSoundsDesc,
              value: p.completionSounds,
              onChanged: (v) => repo.set(PrefKeys.completionSounds, v),
            ),
          ],
        ),
      ],
    );
  }
}

/// S-57 Reliability: notifications, precise timing, battery — each with Fix — and the test reminder.
class ReliabilityPage extends ConsumerStatefulWidget {
  const ReliabilityPage({super.key});

  @override
  ConsumerState<ReliabilityPage> createState() => _ReliabilityPageState();
}

class _ReliabilityPageState extends ConsumerState<ReliabilityPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() => ref.read(permissionsProvider.notifier).refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(permissionsProvider.notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final p = ref.watch(permissionsProvider);
    final a = ref.read(servicesProvider).alarms;
    Widget status(String label, bool good, String value, IconData icon, VoidCallback fix) => FormRow(
      icon: icon,
      color: good ? c.success : c.warning,
      label: label,
      value: value,
      trailing: good ? Icon(AppIcons.ok, color: c.success) : TextButton(onPressed: fix, child: Text(l10n.actionFix)),
    );
    return _Sub(
      title: l10n.secReliability,
      icon: AppIcons.reliability,
      color: p.notifications && p.exactAlarms && p.batteryUnrestricted ? c.success : c.warning,
      caption: l10n.heroReliability,
      children: [
        InsetGroup(
          indent: 56,
          children: [
            status(
              l10n.relNotifications,
              p.notifications,
              p.notifications ? l10n.relOn : l10n.relOff,
              AppIcons.notifications,
              a.requestNotificationPermission,
            ),
            status(
              l10n.relPrecise,
              p.exactAlarms,
              p.exactAlarms ? l10n.relOn : l10n.relOff,
              AppIcons.precise,
              a.openExactAlarmSettings,
            ),
            status(
              l10n.relBattery,
              p.batteryUnrestricted,
              p.batteryUnrestricted ? l10n.relOff : l10n.relBatteryOn,
              AppIcons.battery,
              a.openBatteryOptimizationSettings,
            ),
          ],
        ),
        const Padding(padding: EdgeInsets.all(Space.l), child: TestReminderPanel()),
        if (ref.read(servicesProvider).prefs.string(PrefKeys.lastTest) case final last?)
          _Desc(l10n.relLastTest(_lastTestLabel(l10n, last))),
        const SizedBox(height: Space.l),
        InsetGroup(
          indent: 56,
          children: [
            FormRow(
              icon: AppIcons.diagnostics,
              color: c.textSecondary,
              label: l10n.drawerDiagnostics,
              onTap: () => context.push('/diagnostics'),
            ),
          ],
        ),
      ],
    );
  }

  static String _lastTestLabel(AppLocalizations l10n, String raw) {
    final parts = raw.split(':');
    return switch (parts.first) {
      'ok' => l10n.testOk,
      'late' => l10n.testLate(int.tryParse(parts.last) ?? 0),
      _ => l10n.testFail,
    };
  }
}

/// S-58 Backup & about: export / import (FL-17, DAT-5), privacy policy, version, feedback.
class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final c = AppColors.of(context);
    final s = ref.read(servicesProvider);
    final messenger = ScaffoldMessenger.of(context);
    return _Sub(
      title: l10n.secBackup,
      icon: AppIcons.backup,
      color: c.meeting,
      caption: l10n.heroBackup,
      children: [
        InsetGroup(
          indent: 56,
          children: [
            FormRow(
              icon: AppIcons.exportFile,
              color: c.accent,
              label: l10n.backupExport,
              onTap: () async {
                final p = s.platform;
                if (p == null) return;
                final json = await s.backup.export();
                final uri = await p.saveBackup(s.backup.fileName(DateTime.now()), json);
                if (uri != null) messenger.showSnackBar(SnackBar(content: Text(l10n.backupExported)));
              },
            ),
            FormRow(
              icon: AppIcons.importFile,
              color: c.success,
              label: l10n.backupImport,
              onTap: () => _import(context, ref),
            ),
          ],
        ),
        const SizedBox(height: Space.l),
        InsetGroup(
          indent: 56,
          children: [
            FormRow(
              icon: AppIcons.privacy,
              color: c.meeting,
              label: l10n.aboutPrivacy,
              onTap: () => showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(l10n.aboutPrivacy),
                  content: Text(l10n.privacyText),
                  actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.actionClose))],
                ),
              ),
            ),
            FormRow(
              icon: AppIcons.feedback,
              color: c.event,
              label: l10n.aboutFeedback,
              onTap: () => _sendFeedback(context, ref),
            ),
            FormRow(
              icon: AppIcons.licenses,
              color: c.textSecondary,
              label: l10n.aboutLicenses,
              onTap: () =>
                  showLicensePage(context: context, applicationName: l10n.appName, applicationVersion: appVersion),
            ),
            FormRow(icon: AppIcons.info, color: c.textSecondary, label: l10n.aboutVersion(appVersion)),
          ],
        ),
      ],
    );
  }

  /// S-58: email with app version and device model only — never reminder content.
  Future<void> _sendFeedback(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    var device = '';
    try {
      device = await ref.read(servicesProvider).platform?.deviceInfo() ?? '';
    } catch (_) {}
    // Encode by hand: queryParameters would turn spaces into "+", which mail apps show literally.
    final uri = Uri.parse(
      'mailto:$feedbackEmail'
      '?subject=${Uri.encodeComponent(l10n.feedbackSubject(appVersion))}'
      '&body=${Uri.encodeComponent(l10n.feedbackBody(appVersion, device))}',
    );
    var opened = false;
    try {
      opened = await launchUrl(uri);
    } catch (_) {}
    if (!opened) messenger.showSnackBar(SnackBar(content: Text(l10n.feedbackNoMailApp(feedbackEmail))));
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final s = ref.read(servicesProvider);
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final text = await s.platform?.openBackup();
    if (text == null) return;
    final preview = await s.backup.preview(text);
    if (preview == null) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.backupBadFile)));
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.backupImport),
        content: Text(l10n.backupSummary(preview.total, preview.newer, preview.same)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.actionCancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.actionImport)),
        ],
      ),
    );
    if (ok != true) return;
    final n = await s.backup.import(preview);
    await s.service.resync();
    messenger.showSnackBar(SnackBar(content: Text(l10n.backupImported(n))));
  }
}
