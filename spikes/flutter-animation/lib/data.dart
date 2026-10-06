// 200 fake reminders in groups for Scene B (same generator logic as the RN spike)
import 'theme.dart';

enum Group { overdue, today, tomorrow, later }

extension GroupLabel on Group {
  String get label => const ['Overdue', 'Today', 'Tomorrow', 'Later'][index];
}

class Reminder {
  final String id, title, when;
  final Kind kind;
  final Group group;
  final bool work;
  const Reminder({required this.id, required this.title, required this.when, required this.kind, required this.group, required this.work});
}

const _titles = [
  'Pay rent', 'Call mom', 'Submit report', "Mom's birthday", 'Team standup', 'Dentist',
  'Buy flowers', 'Renew passport', 'Cancel Netflix trial', 'Change AC filter', 'Client call',
  'Dinner with Sam', 'Water plants', 'Send invoice to ACME', 'Pick up dry cleaning', 'Gym',
  'Book hotel', 'Return shoes', 'Prepare deck for board', 'Car insurance renews',
];
const _kinds = [Kind.task, Kind.task, Kind.task, Kind.occasion, Kind.meeting, Kind.event];
const _whens = {
  Group.overdue: ['Yesterday', 'Mon', 'Sat'],
  Group.today: ['9:00 AM', '11:30 AM', '2:00 PM', '6:00 PM', 'Today'],
  Group.tomorrow: ['8:00 AM', '10:00 AM', '3:30 PM', 'Tomorrow'],
  Group.later: ['Fri, Oct 9', 'Mon, Oct 12', 'Thu, Oct 15', 'Oct 30', 'Nov 1'],
};

List<Reminder> makeReminders([int count = 200]) => List.generate(count, (i) {
      final group = i < 6
          ? Group.overdue
          : i < 14
              ? Group.today
              : i < 30
                  ? Group.tomorrow
                  : Group.later;
      final kind = _kinds[i % _kinds.length];
      final whens = _whens[group]!;
      return Reminder(
        id: 'r$i',
        title: _titles[i % _titles.length],
        when: whens[i % whens.length],
        kind: kind,
        group: group,
        work: kind == Kind.meeting || i % 5 == 0,
      );
    });
