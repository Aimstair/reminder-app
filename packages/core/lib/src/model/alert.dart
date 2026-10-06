/// Alert plans (ALR-*): a list of stages, each an offset from the anchor plus channels.
library;

import 'enums.dart';

enum OffsetUnit { minutes, hours, days, weeks, months }

/// Offset from the anchor (ALR-1). Negative = before. Serialized as `-7d`, `-30m`, `-6mo`, `0`.
class AlertOffset {
  const AlertOffset(this.amount, this.unit);

  static const zero = AlertOffset(0, OffsetUnit.minutes);

  /// Signed amount; `-7` with [OffsetUnit.days] = 7 days before.
  final int amount;
  final OffsetUnit unit;

  static const _suffix = {
    OffsetUnit.minutes: 'm',
    OffsetUnit.hours: 'h',
    OffsetUnit.days: 'd',
    OffsetUnit.weeks: 'w',
    OffsetUnit.months: 'mo',
  };

  static final _re = RegExp(r'^([+-]?\d+)(mo|m|h|d|w)?$');

  factory AlertOffset.parse(String s) {
    final m = _re.firstMatch(s.trim());
    if (m == null) throw FormatException('Bad alert offset "$s"');
    final amount = int.parse(m.group(1)!);
    final unit = switch (m.group(2)) {
      'h' => OffsetUnit.hours,
      'd' => OffsetUnit.days,
      'w' => OffsetUnit.weeks,
      'mo' => OffsetUnit.months,
      _ => OffsetUnit.minutes,
    };
    return AlertOffset(amount, unit);
  }

  @override
  String toString() => amount == 0 ? '0' : '$amount${_suffix[unit]}';

  @override
  bool operator ==(Object other) => other is AlertOffset && other.amount == amount && other.unit == unit;

  @override
  int get hashCode => Object.hash(amount, unit);
}

class AlertStage {
  const AlertStage(this.offset, {this.channels = const {AlertChannel.push}, this.label});

  final AlertOffset offset;
  final Set<AlertChannel> channels;

  /// Optional label shown in the notification, e.g. "Start by" (ALR-5).
  final String? label;

  bool get isPrep => offset.amount < 0; // OCC-3: stages before the anchor

  Map<String, Object?> toJson() => {
    'offset': offset.toString(),
    'channels': channels.map((c) => c.name).toList(),
    if (label != null) 'label': label,
  };

  factory AlertStage.fromJson(Map<String, Object?> j) => AlertStage(
    AlertOffset.parse(j['offset']! as String),
    channels: ((j['channels'] as List?) ?? const ['push']).map((c) => AlertChannel.values.byName(c as String)).toSet(),
    label: j['label'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      other is AlertStage &&
      other.offset == offset &&
      other.label == label &&
      other.channels.length == channels.length &&
      other.channels.containsAll(channels);

  @override
  int get hashCode => Object.hash(offset, label, Object.hashAllUnordered(channels));
}

/// ALR-4 default alert plans per type (PRF-9 can override).
List<AlertStage> defaultAlertPlan(Kind kind, TimingType timing) => switch (kind) {
  Kind.meeting => const [AlertStage(AlertOffset(-10, OffsetUnit.minutes))],
  Kind.event => const [AlertStage(AlertOffset(-1, OffsetUnit.hours))],
  Kind.occasion => const [
    AlertStage(AlertOffset(-7, OffsetUnit.days)),
    AlertStage(AlertOffset(-1, OffsetUnit.days)),
    AlertStage(AlertOffset.zero),
  ],
  Kind.task => const [AlertStage(AlertOffset.zero)],
};
