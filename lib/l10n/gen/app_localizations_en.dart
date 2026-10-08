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

  @override
  String get actionPrepared => 'I\'m prepared';

  @override
  String get actionReschedule => 'Reschedule';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionMarkNotDone => 'Mark as not done';

  @override
  String get actionRemindMe => 'Remind me';

  @override
  String get actionMerge => 'Merge';

  @override
  String get actionKeepBoth => 'Keep both';

  @override
  String get actionClose => 'Close';

  @override
  String get detailWhen => 'When';

  @override
  String get detailNotes => 'Notes';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailTimeZone => 'Time zone';

  @override
  String get stateDone => 'Done';

  @override
  String get stateSkipped => 'Skipped';

  @override
  String get statePrepared => 'Prepared';

  @override
  String get statePassed => 'Over';

  @override
  String get stateSnoozed => 'Snoozed';

  @override
  String get statePending => 'Open';

  @override
  String get stateOverdue => 'Overdue';

  @override
  String get contactRemoved => 'Contact removed';

  @override
  String get dupBanner => 'This looks like it\'s on your calendar.';

  @override
  String get snackSkipped => 'Skipped';

  @override
  String get snackDeleted => 'Deleted';

  @override
  String get snackPrepared => 'Prepared';

  @override
  String get occasionDone => 'Hope it\'s a great one!';

  @override
  String get firstDoneTitle => 'Your first one!';

  @override
  String get firstDoneSub => 'That\'s how it\'s done.';

  @override
  String get rescheduleTitle => 'Reschedule';

  @override
  String get reschedLaterToday => 'Later today';

  @override
  String get reschedEvening => 'This evening';

  @override
  String get reschedTomorrow => 'Tomorrow';

  @override
  String get reschedNextWeek => 'Next week';

  @override
  String get reschedPick => 'Pick date & time';

  @override
  String get scopeEditTitle => 'Change which reminders?';

  @override
  String get scopeDeleteTitle => 'Delete which reminders?';

  @override
  String get scopeRemindTitle => 'Apply to which events?';

  @override
  String get scopeThisOne => 'This one';

  @override
  String get scopeThisAndFuture => 'This and future';

  @override
  String get scopeAll => 'All';

  @override
  String get scopeThisEvent => 'This event';

  @override
  String get scopeAllEvents => 'All events in series';

  @override
  String get remind10m => '10 min before';

  @override
  String get remind1h => '1 hour before';

  @override
  String get remind1d => '1 day before';

  @override
  String get remindCustom => 'Custom…';

  @override
  String get remindAtStart => 'At start';

  @override
  String get editorTitle => 'Edit reminder';

  @override
  String get fieldTitle => 'Title';

  @override
  String get fieldNotes => 'Notes';

  @override
  String get fieldStart => 'Starts';

  @override
  String get fieldEnd => 'Ends';

  @override
  String get fieldAllDay => 'All day';

  @override
  String get fieldTimeZone => 'Time zone';

  @override
  String get fieldType => 'Type';

  @override
  String get fieldContext => 'Context';

  @override
  String get noEnd => 'None';

  @override
  String get addAlert => 'Add alert';

  @override
  String get repeatAfterDoneToggle => 'Count from when it\'s done';

  @override
  String get repeatLastBusinessDay => 'Last business day of the month';

  @override
  String get nagOff => 'Off';

  @override
  String get startBy => 'Start by';

  @override
  String get zoneSearch => 'Search time zones';

  @override
  String get pickerDone => 'Done';

  @override
  String get drawerTypes => 'Types';

  @override
  String get drawerContext => 'Context';

  @override
  String get drawerCalendars => 'Calendars';

  @override
  String get searchHint => 'Search reminders';

  @override
  String get completedEmptyTitle => 'Nothing done yet';

  @override
  String get completedEmptySub => 'Finished reminders will show up here.';

  @override
  String get filterEmpty => 'No reminders match your filters';

  @override
  String get actionClearFilters => 'Clear filters';

  @override
  String get digestTitle => 'Your day';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String get digestOverdue => 'Overdue';

  @override
  String get digestMissed => 'Missed while you were away';

  @override
  String get digestComingUp => 'Coming up';

  @override
  String get digestRemoved => 'Removed from your calendar';

  @override
  String get digestStale => 'Overdue for a month. Still relevant?';

  @override
  String get actionKeep => 'Keep';

  @override
  String get digestSuggestions => 'New birthdays in your contacts';

  @override
  String get actionAdd => 'Add';

  @override
  String get bannerNotifOff =>
      'Notifications are off — you won\'t be reminded.';

  @override
  String get actionTurnOn => 'Turn on';

  @override
  String get bannerExact => 'Reminders may arrive up to 10 minutes late.';

  @override
  String get actionFix => 'Fix';

  @override
  String get bannerCalendarOff => 'Calendar access was turned off.';

  @override
  String get actionReconnect => 'Reconnect';

  @override
  String get bannerBattery => 'Your phone may be delaying reminders.';

  @override
  String get actionShowMe => 'Show me how';

  @override
  String get obWelcomeTitle => 'Never forget the things that matter.';

  @override
  String get obWelcomeSub =>
      'Birthdays, bills, meetings, errands — one place, gentle nudges.';

  @override
  String get actionGetStarted => 'Get started';

  @override
  String get obTypeTitle => 'Just type it.';

  @override
  String get obTypeSub =>
      'Write it like you\'d say it. We\'ll handle the rest.';

  @override
  String get obTypeDemo => 'Mom\'s birthday Oct 12';

  @override
  String get obTryOwn => 'Try your own';

  @override
  String get obTypePlaceholder => 'e.g. Pay rent on the 1st every month';

  @override
  String get actionSaveThis => 'Save this';

  @override
  String get actionNext => 'Next';

  @override
  String get actionSkipStep => 'Skip';

  @override
  String get obBellBirthday => 'Ooh, a birthday. Got it.';

  @override
  String get obNudgeTitle => 'Nudged before it matters.';

  @override
  String get obNudgeSub =>
      'Drag through the week. For big days, you get a heads-up early — not just on the day.';

  @override
  String get obDragHint => 'Drag me →';

  @override
  String get obPreparedNote => 'Prepared? We\'ll stop the early nudges.';

  @override
  String get obScheduleTitle => 'Your schedule';

  @override
  String get obScheduleSub =>
      'We picked sensible defaults. Change anything you like.';

  @override
  String get rowTimeZone => 'Time zone';

  @override
  String get rowDateOnlyAt => 'Date-only reminders at';

  @override
  String get rowDateOnlyAtSub =>
      'For things without a time, like \"pay rent on the 1st\"';

  @override
  String get rowNagHours => 'Repeat reminders between';

  @override
  String get rowNagHoursSub => 'We only nag you during these hours';

  @override
  String get rowTomorrowMeans => '\"Tomorrow\" means';

  @override
  String get tomorrowSameTime => 'Same time tomorrow';

  @override
  String get actionLooksGood => 'Looks good';

  @override
  String get obCalTitle => 'See your calendar here too';

  @override
  String get obCalSub =>
      'Your events show up next to your reminders. Read-only — we\'ll never change your calendar, and events won\'t ring unless you ask.';

  @override
  String get actionConnectCalendar => 'Connect calendar';

  @override
  String get actionNotNow => 'Not now';

  @override
  String get obPickCalTitle => 'Which calendars?';

  @override
  String get obPickCalSub => 'You can change this anytime in Settings.';

  @override
  String get obContactsTitle => 'Never miss a birthday';

  @override
  String get obContactsSub =>
      'Add birthdays and anniversaries from your contacts. Only the dates are used — nothing leaves your phone.';

  @override
  String get actionAddBirthdays => 'Add birthdays';

  @override
  String get actionImport => 'Import';

  @override
  String get obBellParty => 'Party planning starts now.';

  @override
  String get testTitle => 'Want to make sure it works?';

  @override
  String get testSub =>
      'We\'ll send a test reminder in 15 seconds. Lock your phone to try it for real.';

  @override
  String get actionSendTest => 'Send test reminder';

  @override
  String get testNotifTitle => 'Test reminder';

  @override
  String get testNotifBody => 'It works! 🔔';

  @override
  String get testOk => 'Reminders are working';

  @override
  String get testFail => 'The test didn\'t arrive';

  @override
  String get testWaiting => 'Test reminder on its way…';

  @override
  String get testFixExact => 'Turn on precise timing.';

  @override
  String get testFixBattery => 'Let the app run in the background.';

  @override
  String get testSteps =>
      'Let\'s fix it: check notifications, precise timing, battery optimization and Do Not Disturb.';

  @override
  String get notifTitle => 'Let us ring the bell';

  @override
  String get notifSub =>
      'Allow notifications so your reminders reach you on time.';

  @override
  String get actionContinue => 'Continue';

  @override
  String get exactTitle => 'Right on time';

  @override
  String get exactSub =>
      'Allow \"Alarms & reminders\" so alerts arrive on the minute, not up to 10 minutes late.';

  @override
  String get actionOpenSettings => 'Open settings';

  @override
  String get batteryTitle => 'Keep reminders reliable';

  @override
  String get actionLater => 'Later';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get secSchedule => 'Your schedule';

  @override
  String get secTimeZone => 'Time zone';

  @override
  String get secDefaultAlerts => 'Default alerts';

  @override
  String get secNotifications => 'Notifications & digest';

  @override
  String get secCalendars => 'Calendars & contacts';

  @override
  String get secViews => 'Views & appearance';

  @override
  String get secReliability => 'Reliability';

  @override
  String get secBackup => 'Backup & about';

  @override
  String get setDefaultZone => 'Default time zone';

  @override
  String get setDefaultZoneDesc => 'New reminders use this time zone.';

  @override
  String get setAskTravel => 'Ask when I travel';

  @override
  String get setAskTravelDesc =>
      'Offer to switch time zones when you\'re somewhere new.';

  @override
  String get setDayTime => 'Date-only reminders at';

  @override
  String get setDayTimeDesc => 'Alert time for reminders without a time.';

  @override
  String get setNagHours => 'Nag hours';

  @override
  String get setNagHoursDesc => 'Repeat alerts only between these times.';

  @override
  String get setTomorrow => '\"Tomorrow\" means';

  @override
  String get setTomorrowDesc =>
      'When \"Tomorrow\" on a notification brings it back.';

  @override
  String get setLateAlerts => 'Late alerts';

  @override
  String get setLateAlertsDesc =>
      'If your phone was off, still show alerts up to this late.';

  @override
  String get late30m => '30 min';

  @override
  String get late2h => '2 hours';

  @override
  String get late6h => '6 hours';

  @override
  String get lateAlways => 'Always';

  @override
  String get setDigestTime => 'Digest time';

  @override
  String get setDigestTimeDesc => 'When your daily summary arrives.';

  @override
  String get setDigestNotif => 'Digest notification';

  @override
  String get setDigestNotifDesc =>
      'Get a notification when your digest is ready.';

  @override
  String get setDefaultAlertsDesc =>
      'Alerts new reminders start with, by type.';

  @override
  String get resetDefault => 'Use default';

  @override
  String get setSounds => 'Completion sounds';

  @override
  String get setSoundsDesc => 'Play a sound when you complete a reminder.';

  @override
  String get setStartIn => 'Start in';

  @override
  String get startLast => 'Last used';

  @override
  String get setShowCompleted => 'Show completed in calendar views';

  @override
  String get setTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get relNotifications => 'Notifications';

  @override
  String get relPrecise => 'Precise timing';

  @override
  String get relBattery => 'Battery optimization';

  @override
  String get relOn => 'On';

  @override
  String get relOff => 'Off';

  @override
  String get relBatteryOn => 'On (may delay reminders)';

  @override
  String get zoneDialogTitle => 'Change default time zone?';

  @override
  String get zoneOnlyNew => 'Only new reminders';

  @override
  String get zoneMoveUpcoming => 'Also move upcoming reminders';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get calDisconnect => 'Disconnect calendar';

  @override
  String get calPermissionOff => 'Calendar access is off';

  @override
  String get contactsBirthdays => 'Contact birthdays';

  @override
  String get setAutoAdd => 'Auto-add new birthdays';

  @override
  String get setAutoAddDesc =>
      'New birthdays in your contacts are added automatically.';

  @override
  String get contactsReview => 'Review birthdays';

  @override
  String get backupExport => 'Export backup';

  @override
  String get backupImport => 'Import backup';

  @override
  String get backupBadFile => 'This file isn\'t a Reminder App backup.';

  @override
  String get backupExported => 'Backup saved';

  @override
  String get aboutPrivacy => 'Privacy policy';

  @override
  String get aboutFeedback => 'Send feedback';

  @override
  String get privacyText =>
      'Your reminders stay on this phone. Reminder App has no account and no server in this version: nothing you type, no calendar event and no contact leaves your device. Backups are files you save yourself.';

  @override
  String get errVoice => 'Voice input isn\'t available on this phone.';

  @override
  String get errSpeech => 'Didn\'t catch that. Try again?';

  @override
  String get errSave => 'Couldn\'t save. Please try again.';

  @override
  String get errCalendar => 'Couldn\'t load your calendar. Pull to retry.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String get tplBirthday => 'Birthday';

  @override
  String get tplBill => 'Bill due';

  @override
  String get tplRenewal => 'Renewal';

  @override
  String get tplTrial => 'Free trial';

  @override
  String get tplNightOut => 'Night out';

  @override
  String get tplAppointment => 'Appointment';

  @override
  String get tplPhBirthday => 'Whose birthday? When?';

  @override
  String get tplPhBill => 'Which bill? Due on the…';

  @override
  String get tplPhRenewal => 'What renews? When?';

  @override
  String get tplPhTrial => 'Which trial?';

  @override
  String get tplPhNightOut => 'Where and when?';

  @override
  String get tplPhAppointment => 'What and when?';

  @override
  String get actionSpeak => 'Speak';

  @override
  String get listening => 'Listening…';

  @override
  String get sharedSaved => 'Reminder saved';

  @override
  String get widgetEmpty => 'Nothing coming up';

  @override
  String get moreOptions => 'More options';

  @override
  String detailFromCalendar(String calendar) {
    return 'From $calendar';
  }

  @override
  String zoneNote(String time, String city) {
    return '$time in $city';
  }

  @override
  String snackRescheduled(String when) {
    return 'Rescheduled to $when';
  }

  @override
  String snackNext(String date) {
    return 'Done · Next: $date';
  }

  @override
  String snackSkippedNext(String date) {
    return 'Skipped · Next: $date';
  }

  @override
  String everyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String everyWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String everyMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String everyYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String everyWeekday(String weekday) {
    return 'Every $weekday';
  }

  @override
  String monthlyOnDay(String nth) {
    return 'Every month on the $nth';
  }

  @override
  String nagEvery(String interval) {
    return 'Every $interval';
  }

  @override
  String overdueCount(int count) {
    return 'Overdue ($count)';
  }

  @override
  String moreCount(int count) {
    return '+$count more';
  }

  @override
  String searchEmpty(String query) {
    return 'No matches for \"$query\"';
  }

  @override
  String searchCreate(String query) {
    return 'Create \"$query\"';
  }

  @override
  String digestMissedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count alerts weren\'t shown',
      one: '1 alert wasn\'t shown',
    );
    return '$_temp0';
  }

  @override
  String tomorrowAtTime(String time) {
    return 'Tomorrow at $time';
  }

  @override
  String contactsFound(int birthdays, int anniversaries) {
    return '$birthdays birthdays, $anniversaries anniversaries found';
  }

  @override
  String testLate(int seconds) {
    return 'Arrived $seconds seconds late';
  }

  @override
  String batterySub(String brand) {
    return 'Your $brand phone may pause apps to save battery. One quick setting keeps your reminders on time.';
  }

  @override
  String relLastTest(String result) {
    return 'Last test: $result';
  }

  @override
  String zoneConfirm(int count, String zone) {
    return '$count upcoming reminders will keep their clock time in $zone.';
  }

  @override
  String backupSummary(int total, int newer, int same) {
    return '$total reminders found · $newer newer than yours · $same already here';
  }

  @override
  String backupImported(int count) {
    return 'Imported $count reminders.';
  }

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String timeRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String digestPartOverdue(int count) {
    return '$count overdue';
  }

  @override
  String digestPartComing(int count) {
    return '$count coming up';
  }

  @override
  String travelTitle(String city) {
    return 'You\'re in $city';
  }

  @override
  String get travelBody => 'Switch your default time zone?';

  @override
  String get actionSwitch => 'Switch';

  @override
  String actionKeepCity(String city) {
    return 'Keep $city';
  }

  @override
  String drawerCalendarsHidden(int count) {
    return '$count hidden';
  }

  @override
  String stateSnoozedUntil(String time) {
    return 'Snoozed until $time';
  }

  @override
  String get captureSharedInNotes => 'Shared text and links saved in notes';

  @override
  String feedbackSubject(String version) {
    return 'Reminder App feedback ($version)';
  }

  @override
  String feedbackBody(String version, String device) {
    return 'Tell us what happened or what you\'d like to see:\n\n\n\n—\nApp $version · $device';
  }

  @override
  String feedbackNoMailApp(String email) {
    return 'No email app found. Write to us at $email.';
  }

  @override
  String get aboutLicenses => 'Open-source licences';
}
