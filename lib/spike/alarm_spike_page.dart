// TEMPORARY v0 spike screen for the exact-alarm reliability test (ROADMAP v0, docs/testing.md §3).
// Not part of the app UI: hard-coded strings and colors are intentional here. Delete after v0.
import 'dart:async';

import 'package:flutter/material.dart';

import '../native/alarm_api.g.dart';

class AlarmSpikePage extends StatefulWidget {
  const AlarmSpikePage({super.key});

  @override
  State<AlarmSpikePage> createState() => _AlarmSpikePageState();
}

class _AlarmSpikePageState extends State<AlarmSpikePage> with WidgetsBindingObserver {
  final _api = AlarmHostApi();
  PermissionState? _perm;
  List<RegisteredAlarm> _registered = [];
  List<FireLogEntry> _log = [];
  List<JournalEntry> _journal = [];
  Timer? _ticker;

  static const _cutoff = 2 * 60 * 60 * 1000; // PRF-6 default: 2 hours

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _ticker = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final perm = await _api.getPermissionState();
    final reg = await _api.registered();
    final log = await _api.getFireLog(0);
    final journal = await _api.readJournal();
    if (!mounted) return;
    setState(() {
      _perm = perm;
      _registered = reg;
      _log = log;
      _journal = journal;
    });
  }

  /// Adds alarms to what's already registered (sync replaces the whole set — SCH-4).
  Future<void> _add(List<AlarmSpec> specs) async {
    final existing = (await _api.registered()).map((r) => r.spec).toList();
    final keys = specs.map((s) => s.key).toSet();
    await _api.sync([...existing.where((s) => !keys.contains(s.key)), ...specs]);
    await _refresh();
  }

  AlarmSpec _spec(String occ, String stage, Duration inFuture, String title, String body, String kind) {
    final at = DateTime.now().add(inFuture).millisecondsSinceEpoch;
    return AlarmSpec(
      key: '$occ:$stage:0',
      fireAtUtcMs: at,
      title: title,
      body: body,
      kind: kind,
      lateCutoffMs: _cutoff,
    );
  }

  String _id() => DateTime.now().millisecondsSinceEpoch.toString();

  String _t(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = _perm;
    final shown = _log.where((e) => e.outcome == 'shown').length;
    final late = _log.where((e) => e.outcome == 'late').length;
    final missed = _log.where((e) => e.outcome == 'missed').length;
    final delays = _log.where((e) => e.outcome != 'missed').map((e) => e.firedAtMs - e.scheduledAtMs).toList()
      ..sort();
    final maxDelay = delays.isEmpty ? 0 : delays.last;

    return Scaffold(
      appBar: AppBar(title: const Text('Alarm reliability spike'), actions: [
        IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh), tooltip: 'Refresh'),
      ]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Permissions'),
            if (p != null) ...[
              _permRow('Notifications', p.notifications, 'Request', _api.requestNotificationPermission),
              _permRow('Exact alarms', p.exactAlarms, 'Open settings', _api.openExactAlarmSettings),
              _permRow('Battery: unrestricted', p.ignoringBatteryOptimizations, 'Open settings',
                  _api.openBatteryOptimizationSettings),
            ],
            const SizedBox(height: 12),
            _section('Schedule tests'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _btn('Test in 15 s', () => _add([_spec(_id(), 'test', const Duration(seconds: 15), 'Test reminder', 'It works!', 'test')])),
              _btn('Task in 1 min', () => _add([_spec(_id(), 'at', const Duration(minutes: 1), 'Pay rent', 'Now · due today', 'task')])),
              _btn('Occasion: prep 1 min + day-of 3 min', () {
                final occ = _id();
                return _add([
                  _spec(occ, 'prep', const Duration(minutes: 1), "Mom's birthday", 'In 1 week · Mon, Oct 12', 'occasion_prep'),
                  _spec(occ, 'day', const Duration(minutes: 3), "Mom's birthday", 'Today', 'occasion_day'),
                ]);
              }),
              _btn('Meeting in 2 min', () => _add([_spec(_id(), 'm10', const Duration(minutes: 2), 'Client call', 'In 10 min · 11:00 AM', 'meeting')])),
              _btn('5 at the same minute (+1 min)', () {
                final base = _id();
                return _add([
                  for (var i = 0; i < 5; i++)
                    _spec('$base-$i', 'at', const Duration(minutes: 1), 'Burst #${i + 1}', 'Same-minute test', 'task'),
                ]);
              }),
              _btn('Reboot test (+4 min)', () => _add([_spec(_id(), 'reboot', const Duration(minutes: 4), 'Reboot test', 'Fired after reboot', 'test')])),
              _btn('Doze test (+45 min)', () => _add([_spec(_id(), 'doze', const Duration(minutes: 45), 'Doze test', 'Phone idle 45 min', 'test')])),
              _btn('Late test: due 30 min ago', () => _add([_spec(_id(), 'late', const Duration(minutes: -30), 'Late test', 'Should show as late', 'test')])),
              _btn('Missed test: due 3 h ago', () => _add([_spec(_id(), 'miss', const Duration(hours: -3), 'Missed test', 'Should be missed', 'test')])),
              OutlinedButton(
                onPressed: () async {
                  await _api.sync([]);
                  await _api.clearLogs();
                  await _refresh();
                },
                child: const Text('Clear all'),
              ),
            ]),
            const SizedBox(height: 16),
            _section('Registered (${_registered.length})'),
            for (final r in _registered)
              ListTile(
                dense: true,
                title: Text(r.spec.title),
                subtitle: Text('${r.spec.key}\n${_t(r.spec.fireAtUtcMs)} · ${r.spec.kind}'),
                trailing: Text(r.exact ? 'exact' : 'inexact', style: TextStyle(color: r.exact ? Colors.green : Colors.orange)),
              ),
            const SizedBox(height: 16),
            _section('Fire log — $shown on time · $late late · $missed missed · max delay ${(maxDelay / 1000).toStringAsFixed(1)} s'),
            for (final e in _log)
              ListTile(
                dense: true,
                title: Text('${e.outcome.toUpperCase()} · ${((e.firedAtMs - e.scheduledAtMs) / 1000).toStringAsFixed(1)} s'),
                subtitle: Text('${e.alarmKey}\nscheduled ${_t(e.scheduledAtMs)} · fired ${_t(e.firedAtMs)}'),
                trailing: Icon(
                  e.outcome == 'shown' ? Icons.check_circle : (e.outcome == 'late' ? Icons.schedule : Icons.error),
                  color: e.outcome == 'shown' ? Colors.green : (e.outcome == 'late' ? Colors.orange : Colors.red),
                ),
              ),
            const SizedBox(height: 16),
            _section('Notification button journal (${_journal.length} unapplied)'),
            for (final j in _journal)
              ListTile(
                dense: true,
                title: Text(j.action.split('.').last),
                subtitle: Text('${j.alarmKey} · ${_t(j.actedAtMs)}'),
              ),
            if (_journal.isNotEmpty)
              TextButton(
                onPressed: () async {
                  await _api.markApplied(_journal.map((j) => j.id).toList());
                  await _refresh();
                },
                child: const Text('Mark journal applied'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      );

  Widget _btn(String label, Future<void> Function() onTap) => FilledButton.tonal(onPressed: onTap, child: Text(label));

  Widget _permRow(String label, bool ok, String action, Future<void> Function() onTap) => Row(children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : Colors.red, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
        if (!ok) TextButton(onPressed: onTap, child: Text(action)),
      ]);
}
