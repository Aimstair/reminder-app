// 200 fake reminders in groups for Scene B (same generator logic as the Flutter spike)
import type { Kind } from './theme';

export type Group = 'Overdue' | 'Today' | 'Tomorrow' | 'Later';

export type Reminder = {
  id: string;
  title: string;
  when: string;
  kind: Kind;
  group: Group;
  work: boolean;
};

const titles = [
  'Pay rent', 'Call mom', 'Submit report', "Mom's birthday", 'Team standup', 'Dentist',
  'Buy flowers', 'Renew passport', 'Cancel Netflix trial', 'Change AC filter', 'Client call',
  'Dinner with Sam', 'Water plants', 'Send invoice to ACME', 'Pick up dry cleaning', 'Gym',
  'Book hotel', 'Return shoes', 'Prepare deck for board', 'Car insurance renews',
];
const kinds: Kind[] = ['task', 'task', 'task', 'occasion', 'meeting', 'event'];
const whens: Record<Group, string[]> = {
  Overdue: ['Yesterday', 'Mon', 'Sat'],
  Today: ['9:00 AM', '11:30 AM', '2:00 PM', '6:00 PM', 'Today'],
  Tomorrow: ['8:00 AM', '10:00 AM', '3:30 PM', 'Tomorrow'],
  Later: ['Fri, Oct 9', 'Mon, Oct 12', 'Thu, Oct 15', 'Oct 30', 'Nov 1'],
};

export function makeReminders(count = 200): Reminder[] {
  const out: Reminder[] = [];
  for (let i = 0; i < count; i++) {
    const group: Group = i < 6 ? 'Overdue' : i < 14 ? 'Today' : i < 30 ? 'Tomorrow' : 'Later';
    const kind = kinds[i % kinds.length];
    out.push({
      id: `r${i}`,
      title: titles[i % titles.length],
      when: whens[group][i % whens[group].length],
      kind,
      group,
      work: kind === 'meeting' || i % 5 === 0,
    });
  }
  return out;
}

export const GROUPS: Group[] = ['Overdue', 'Today', 'Tomorrow', 'Later'];
