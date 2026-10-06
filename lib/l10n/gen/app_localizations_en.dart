// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Reminder App';

  @override
  String notifNow(String time) {
    return 'Now · $time';
  }

  @override
  String get notifToday => 'Today';

  @override
  String notifBefore(String relative, String when) {
    return 'In $relative · $when';
  }

  @override
  String notifStartBy(String when) {
    return 'Start today · due $when';
  }

  @override
  String get notifNagToday => 'Still to do · due today';

  @override
  String notifNagSince(String when) {
    return 'Still to do · due since $when';
  }

  @override
  String relMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min',
      one: '1 min',
    );
    return '$_temp0';
  }

  @override
  String relHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hours',
      one: '1 hour',
    );
    return '$_temp0';
  }

  @override
  String relDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String relWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String relMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get dayTomorrow => 'Tomorrow';

  @override
  String get dayToday => 'today';

  @override
  String get groupOverdue => 'Overdue';

  @override
  String get groupToday => 'Today';

  @override
  String get groupTomorrow => 'Tomorrow';

  @override
  String get groupThisWeek => 'This week';

  @override
  String get groupLater => 'Later';

  @override
  String get viewSchedule => 'Schedule';

  @override
  String get viewDay => 'Day';

  @override
  String get viewMonth => 'Month';

  @override
  String get topToday => 'Today';

  @override
  String get topSearch => 'Search';

  @override
  String get drawerCompleted => 'Completed';

  @override
  String get drawerSettings => 'Settings';

  @override
  String get drawerHelp => 'Help & feedback';

  @override
  String get drawerDiagnostics => 'Alarm diagnostics';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get allDay => 'All day';

  @override
  String get emptyNoneTitle => 'Nothing to remember… yet';

  @override
  String get emptyNoneSub => 'What\'s on your mind?';

  @override
  String get emptyTodayTitle => 'Nothing due today';

  @override
  String get emptyTodaySub => 'Enjoy the quiet.';

  @override
  String get allClearTitle => 'All clear!';

  @override
  String get allClearSub => 'Nothing left for today.';

  @override
  String get snackDone => 'Done';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionDone => 'Done';

  @override
  String get newReminder => 'New reminder';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String progressDone(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get rowDate => 'Date';

  @override
  String get rowTime => 'Time';

  @override
  String get rowRepeat => 'Repeat';

  @override
  String get rowAlerts => 'Alerts';

  @override
  String get rowNag => 'Nag until done';

  @override
  String get repeatNever => 'Never';

  @override
  String get repeatDaily => 'Every day';

  @override
  String get repeatWeekdays => 'Every weekday';

  @override
  String get repeatWeekly => 'Every week';

  @override
  String get repeatMonthly => 'Every month';

  @override
  String get repeatYearly => 'Every year';

  @override
  String get repeatCustom => 'Custom';

  @override
  String get alertAtTime => 'At time';

  @override
  String get alertNone => 'No alerts';

  @override
  String get typeTask => 'Task';

  @override
  String get typeMeeting => 'Meeting';

  @override
  String get typeEvent => 'Event';

  @override
  String get typeOccasion => 'Occasion';

  @override
  String get ctxPersonal => 'Personal';

  @override
  String get ctxWork => 'Work';

  @override
  String get captureEx1 => 'Call mom Sunday 6pm';

  @override
  String get captureEx2 => 'Pay rent on the 1st every month';

  @override
  String get captureEx3 => 'Mom\'s birthday Oct 12';

  @override
  String get captureEx4 => 'Dentist Friday 2:30pm';

  @override
  String get captureEx5 => 'Change AC filter every 3 months after done';

  @override
  String get hintTimeInPast => 'This time has already passed.';

  @override
  String get hintTitleMissing => 'Add a title';

  @override
  String get hintDateMissing => 'When is it?';

  @override
  String snackSaved(String when) {
    return 'Saved · $when';
  }

  @override
  String repeatAfterDone(String every) {
    return '$every after done';
  }

  @override
  String alertBefore(String relative) {
    return '$relative before';
  }

  @override
  String hintAmbiguousTime(String time) {
    return 'Did you mean $time? Tap to change.';
  }

  @override
  String hintAmbiguousDate(String absolute) {
    return 'That\'s $absolute. Tap to change.';
  }

  @override
  String hintPastDateRolled(String absolute) {
    return 'Moved to next year ($absolute).';
  }
}
