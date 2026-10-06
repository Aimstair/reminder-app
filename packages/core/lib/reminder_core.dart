/// Pure-Dart core logic for Reminder App (docs/architecture.md §2). No Flutter imports.
library;

export 'src/calendar/calendar_import.dart';
export 'src/capture/draft.dart';
export 'src/capture/templates.dart';
export 'src/contacts/contacts_import.dart';
export 'src/engine/digest.dart';
export 'src/engine/occurrence_engine.dart';
export 'src/engine/series.dart';
export 'src/model/alert.dart';
export 'src/model/enums.dart';
export 'src/model/ids.dart';
export 'src/model/prefs.dart';
export 'src/model/reminder.dart';
export 'src/model/wall_time.dart';
export 'src/parser/parse_result.dart';
export 'src/parser/parser.dart' show ReminderParser;
export 'src/planner/alarm_planner.dart';
export 'src/recurrence/recurrence.dart';
export 'src/time/calendar.dart';
export 'src/time/zones.dart';
export 'src/views/range.dart';
export 'src/views/schedule.dart';
export 'src/views/search.dart';
