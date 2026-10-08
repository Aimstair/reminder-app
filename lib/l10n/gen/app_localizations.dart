import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'Reminder App'**
  String get appName;

  /// copy.md notif.atTime — datetime reminder at its time
  ///
  /// In en, this message translates to:
  /// **'Now · {time}'**
  String notifNow(String time);

  /// copy.md notif.atTime / notif.occasion.today — date-only reminder on its day
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get notifToday;

  /// copy.md notif.before — e.g. In 1 week · Mon, Oct 12
  ///
  /// In en, this message translates to:
  /// **'In {relative} · {when}'**
  String notifBefore(String relative, String when);

  /// copy.md notif.startBy (ALR-5)
  ///
  /// In en, this message translates to:
  /// **'Start today · due {when}'**
  String notifStartBy(String when);

  /// copy.md notif.nag — still open on its due day
  ///
  /// In en, this message translates to:
  /// **'Still to do · due today'**
  String get notifNagToday;

  /// copy.md notif.nag — overdue from an earlier day
  ///
  /// In en, this message translates to:
  /// **'Still to do · due since {when}'**
  String notifNagSince(String when);

  /// No description provided for @relMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min} other{{count} min}}'**
  String relMinutes(int count);

  /// No description provided for @relHours.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 hour} other{{count} hours}}'**
  String relHours(int count);

  /// No description provided for @relDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String relDays(int count);

  /// No description provided for @relWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week} other{{count} weeks}}'**
  String relWeeks(int count);

  /// No description provided for @relMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month} other{{count} months}}'**
  String relMonths(int count);

  /// Relative day name
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dayTomorrow;

  /// Lowercase 'today' inside a sentence
  ///
  /// In en, this message translates to:
  /// **'today'**
  String get dayToday;

  /// No description provided for @groupOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get groupOverdue;

  /// No description provided for @groupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get groupToday;

  /// No description provided for @groupTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get groupTomorrow;

  /// No description provided for @groupThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get groupThisWeek;

  /// No description provided for @groupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get groupLater;

  /// No description provided for @viewSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get viewSchedule;

  /// No description provided for @viewDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get viewDay;

  /// No description provided for @viewMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get viewMonth;

  /// No description provided for @topToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get topToday;

  /// No description provided for @topSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get topSearch;

  /// No description provided for @drawerCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get drawerCompleted;

  /// No description provided for @drawerSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get drawerSettings;

  /// No description provided for @drawerHelp.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get drawerHelp;

  /// No description provided for @drawerDiagnostics.
  ///
  /// In en, this message translates to:
  /// **'Alarm diagnostics'**
  String get drawerDiagnostics;

  /// No description provided for @greetingMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get greetingMorning;

  /// No description provided for @greetingAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get greetingAfternoon;

  /// No description provided for @greetingEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get greetingEvening;

  /// No description provided for @allDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get allDay;

  /// No description provided for @emptyNoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to remember… yet'**
  String get emptyNoneTitle;

  /// No description provided for @emptyNoneSub.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get emptyNoneSub;

  /// No description provided for @emptyTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing due today'**
  String get emptyTodayTitle;

  /// No description provided for @emptyTodaySub.
  ///
  /// In en, this message translates to:
  /// **'Enjoy the quiet.'**
  String get emptyTodaySub;

  /// No description provided for @allClearTitle.
  ///
  /// In en, this message translates to:
  /// **'All clear!'**
  String get allClearTitle;

  /// No description provided for @allClearSub.
  ///
  /// In en, this message translates to:
  /// **'Nothing left for today.'**
  String get allClearSub;

  /// No description provided for @snackDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get snackDone;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New reminder'**
  String get newReminder;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Daily progress ring label (S-12)
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done'**
  String progressDone(int done, int total);

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @rowDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get rowDate;

  /// No description provided for @rowTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get rowTime;

  /// No description provided for @rowRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get rowRepeat;

  /// No description provided for @rowAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get rowAlerts;

  /// No description provided for @rowNag.
  ///
  /// In en, this message translates to:
  /// **'Nag until done'**
  String get rowNag;

  /// No description provided for @repeatNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNever;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every day'**
  String get repeatDaily;

  /// No description provided for @repeatWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Every weekday'**
  String get repeatWeekdays;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get repeatMonthly;

  /// No description provided for @repeatYearly.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get repeatYearly;

  /// No description provided for @repeatCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get repeatCustom;

  /// No description provided for @alertAtTime.
  ///
  /// In en, this message translates to:
  /// **'At time'**
  String get alertAtTime;

  /// No description provided for @alertNone.
  ///
  /// In en, this message translates to:
  /// **'No alerts'**
  String get alertNone;

  /// No description provided for @typeTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get typeTask;

  /// No description provided for @typeMeeting.
  ///
  /// In en, this message translates to:
  /// **'Meeting'**
  String get typeMeeting;

  /// No description provided for @typeEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get typeEvent;

  /// No description provided for @typeOccasion.
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get typeOccasion;

  /// No description provided for @ctxPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get ctxPersonal;

  /// No description provided for @ctxWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get ctxWork;

  /// No description provided for @captureEx1.
  ///
  /// In en, this message translates to:
  /// **'Call mom Sunday 6pm'**
  String get captureEx1;

  /// No description provided for @captureEx2.
  ///
  /// In en, this message translates to:
  /// **'Pay rent on the 1st every month'**
  String get captureEx2;

  /// No description provided for @captureEx3.
  ///
  /// In en, this message translates to:
  /// **'Mom\'s birthday Oct 12'**
  String get captureEx3;

  /// No description provided for @captureEx4.
  ///
  /// In en, this message translates to:
  /// **'Dentist Friday 2:30pm'**
  String get captureEx4;

  /// No description provided for @captureEx5.
  ///
  /// In en, this message translates to:
  /// **'Change AC filter every 3 months after done'**
  String get captureEx5;

  /// No description provided for @hintTimeInPast.
  ///
  /// In en, this message translates to:
  /// **'This time has already passed.'**
  String get hintTimeInPast;

  /// No description provided for @hintTitleMissing.
  ///
  /// In en, this message translates to:
  /// **'Add a title'**
  String get hintTitleMissing;

  /// No description provided for @hintDateMissing.
  ///
  /// In en, this message translates to:
  /// **'When is it?'**
  String get hintDateMissing;

  /// copy.md Saved snackbar
  ///
  /// In en, this message translates to:
  /// **'Saved · {when}'**
  String snackSaved(String when);

  /// REC-6 summary, e.g. Every 3 months after done
  ///
  /// In en, this message translates to:
  /// **'{every} after done'**
  String repeatAfterDone(String every);

  /// Alert summary, e.g. 10 min before
  ///
  /// In en, this message translates to:
  /// **'{relative} before'**
  String alertBefore(String relative);

  /// copy.md ambiguous_time
  ///
  /// In en, this message translates to:
  /// **'Did you mean {time}? Tap to change.'**
  String hintAmbiguousTime(String time);

  /// copy.md ambiguous_date
  ///
  /// In en, this message translates to:
  /// **'That\'s {absolute}. Tap to change.'**
  String hintAmbiguousDate(String absolute);

  /// copy.md past_date_rolled
  ///
  /// In en, this message translates to:
  /// **'Moved to next year ({absolute}).'**
  String hintPastDateRolled(String absolute);

  /// No description provided for @actionPrepared.
  ///
  /// In en, this message translates to:
  /// **'I\'m prepared'**
  String get actionPrepared;

  /// No description provided for @actionReschedule.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get actionReschedule;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionMarkNotDone.
  ///
  /// In en, this message translates to:
  /// **'Mark as not done'**
  String get actionMarkNotDone;

  /// No description provided for @actionRemindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get actionRemindMe;

  /// No description provided for @actionMerge.
  ///
  /// In en, this message translates to:
  /// **'Merge'**
  String get actionMerge;

  /// No description provided for @actionKeepBoth.
  ///
  /// In en, this message translates to:
  /// **'Keep both'**
  String get actionKeepBoth;

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @detailWhen.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get detailWhen;

  /// No description provided for @detailNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get detailNotes;

  /// No description provided for @detailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailStatus;

  /// No description provided for @detailTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get detailTimeZone;

  /// No description provided for @stateDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get stateDone;

  /// No description provided for @stateSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get stateSkipped;

  /// No description provided for @statePrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get statePrepared;

  /// No description provided for @statePassed.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get statePassed;

  /// No description provided for @stateSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get stateSnoozed;

  /// No description provided for @statePending.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get statePending;

  /// No description provided for @stateOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get stateOverdue;

  /// No description provided for @contactRemoved.
  ///
  /// In en, this message translates to:
  /// **'Contact removed'**
  String get contactRemoved;

  /// No description provided for @dupBanner.
  ///
  /// In en, this message translates to:
  /// **'This looks like it\'s on your calendar.'**
  String get dupBanner;

  /// No description provided for @snackSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get snackSkipped;

  /// No description provided for @snackDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get snackDeleted;

  /// No description provided for @snackPrepared.
  ///
  /// In en, this message translates to:
  /// **'Prepared'**
  String get snackPrepared;

  /// No description provided for @occasionDone.
  ///
  /// In en, this message translates to:
  /// **'Hope it\'s a great one!'**
  String get occasionDone;

  /// No description provided for @firstDoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Your first one!'**
  String get firstDoneTitle;

  /// No description provided for @firstDoneSub.
  ///
  /// In en, this message translates to:
  /// **'That\'s how it\'s done.'**
  String get firstDoneSub;

  /// No description provided for @rescheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get rescheduleTitle;

  /// No description provided for @reschedLaterToday.
  ///
  /// In en, this message translates to:
  /// **'Later today'**
  String get reschedLaterToday;

  /// No description provided for @reschedEvening.
  ///
  /// In en, this message translates to:
  /// **'This evening'**
  String get reschedEvening;

  /// No description provided for @reschedTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get reschedTomorrow;

  /// No description provided for @reschedNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Next week'**
  String get reschedNextWeek;

  /// No description provided for @reschedPick.
  ///
  /// In en, this message translates to:
  /// **'Pick date & time'**
  String get reschedPick;

  /// No description provided for @scopeEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Change which reminders?'**
  String get scopeEditTitle;

  /// No description provided for @scopeDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete which reminders?'**
  String get scopeDeleteTitle;

  /// No description provided for @scopeRemindTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply to which events?'**
  String get scopeRemindTitle;

  /// No description provided for @scopeThisOne.
  ///
  /// In en, this message translates to:
  /// **'This one'**
  String get scopeThisOne;

  /// No description provided for @scopeThisAndFuture.
  ///
  /// In en, this message translates to:
  /// **'This and future'**
  String get scopeThisAndFuture;

  /// No description provided for @scopeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get scopeAll;

  /// No description provided for @scopeThisEvent.
  ///
  /// In en, this message translates to:
  /// **'This event'**
  String get scopeThisEvent;

  /// No description provided for @scopeAllEvents.
  ///
  /// In en, this message translates to:
  /// **'All events in series'**
  String get scopeAllEvents;

  /// No description provided for @remind10m.
  ///
  /// In en, this message translates to:
  /// **'10 min before'**
  String get remind10m;

  /// No description provided for @remind1h.
  ///
  /// In en, this message translates to:
  /// **'1 hour before'**
  String get remind1h;

  /// No description provided for @remind1d.
  ///
  /// In en, this message translates to:
  /// **'1 day before'**
  String get remind1d;

  /// No description provided for @remindCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get remindCustom;

  /// No description provided for @remindAtStart.
  ///
  /// In en, this message translates to:
  /// **'At start'**
  String get remindAtStart;

  /// No description provided for @editorTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get editorTitle;

  /// No description provided for @fieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get fieldTitle;

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get fieldNotes;

  /// No description provided for @fieldStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get fieldStart;

  /// No description provided for @fieldEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get fieldEnd;

  /// No description provided for @fieldAllDay.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get fieldAllDay;

  /// No description provided for @fieldTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get fieldTimeZone;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldType;

  /// No description provided for @fieldContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get fieldContext;

  /// No description provided for @noEnd.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get noEnd;

  /// No description provided for @addAlert.
  ///
  /// In en, this message translates to:
  /// **'Add alert'**
  String get addAlert;

  /// No description provided for @repeatAfterDoneToggle.
  ///
  /// In en, this message translates to:
  /// **'Count from when it\'s done'**
  String get repeatAfterDoneToggle;

  /// No description provided for @repeatLastBusinessDay.
  ///
  /// In en, this message translates to:
  /// **'Last business day of the month'**
  String get repeatLastBusinessDay;

  /// No description provided for @nagOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get nagOff;

  /// No description provided for @startBy.
  ///
  /// In en, this message translates to:
  /// **'Start by'**
  String get startBy;

  /// No description provided for @zoneSearch.
  ///
  /// In en, this message translates to:
  /// **'Search time zones'**
  String get zoneSearch;

  /// No description provided for @pickerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get pickerDone;

  /// No description provided for @drawerTypes.
  ///
  /// In en, this message translates to:
  /// **'Types'**
  String get drawerTypes;

  /// No description provided for @drawerContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get drawerContext;

  /// No description provided for @drawerCalendars.
  ///
  /// In en, this message translates to:
  /// **'Calendars'**
  String get drawerCalendars;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search reminders'**
  String get searchHint;

  /// No description provided for @completedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing done yet'**
  String get completedEmptyTitle;

  /// No description provided for @completedEmptySub.
  ///
  /// In en, this message translates to:
  /// **'Finished reminders will show up here.'**
  String get completedEmptySub;

  /// No description provided for @filterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No reminders match your filters'**
  String get filterEmpty;

  /// No description provided for @actionClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get actionClearFilters;

  /// No description provided for @digestTitle.
  ///
  /// In en, this message translates to:
  /// **'Your day'**
  String get digestTitle;

  /// No description provided for @actionDismiss.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get actionDismiss;

  /// No description provided for @digestOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get digestOverdue;

  /// No description provided for @digestMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed while you were away'**
  String get digestMissed;

  /// No description provided for @digestComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get digestComingUp;

  /// No description provided for @digestRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from your calendar'**
  String get digestRemoved;

  /// No description provided for @digestStale.
  ///
  /// In en, this message translates to:
  /// **'Overdue for a month. Still relevant?'**
  String get digestStale;

  /// No description provided for @actionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get actionKeep;

  /// No description provided for @digestSuggestions.
  ///
  /// In en, this message translates to:
  /// **'New birthdays in your contacts'**
  String get digestSuggestions;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @bannerNotifOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are off — you won\'t be reminded.'**
  String get bannerNotifOff;

  /// No description provided for @actionTurnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get actionTurnOn;

  /// No description provided for @bannerExact.
  ///
  /// In en, this message translates to:
  /// **'Reminders may arrive up to 10 minutes late.'**
  String get bannerExact;

  /// No description provided for @actionFix.
  ///
  /// In en, this message translates to:
  /// **'Fix'**
  String get actionFix;

  /// No description provided for @bannerCalendarOff.
  ///
  /// In en, this message translates to:
  /// **'Calendar access was turned off.'**
  String get bannerCalendarOff;

  /// No description provided for @actionReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get actionReconnect;

  /// No description provided for @bannerBattery.
  ///
  /// In en, this message translates to:
  /// **'Your phone may be delaying reminders.'**
  String get bannerBattery;

  /// No description provided for @actionShowMe.
  ///
  /// In en, this message translates to:
  /// **'Show me how'**
  String get actionShowMe;

  /// No description provided for @obWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Never forget the things that matter.'**
  String get obWelcomeTitle;

  /// No description provided for @obWelcomeSub.
  ///
  /// In en, this message translates to:
  /// **'Birthdays, bills, meetings, errands — one place, gentle nudges.'**
  String get obWelcomeSub;

  /// No description provided for @actionGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get actionGetStarted;

  /// No description provided for @obTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'Just type it.'**
  String get obTypeTitle;

  /// No description provided for @obTypeSub.
  ///
  /// In en, this message translates to:
  /// **'Write it like you\'d say it. We\'ll handle the rest.'**
  String get obTypeSub;

  /// No description provided for @obTypeDemo.
  ///
  /// In en, this message translates to:
  /// **'Mom\'s birthday Oct 12'**
  String get obTypeDemo;

  /// No description provided for @obTryOwn.
  ///
  /// In en, this message translates to:
  /// **'Try your own'**
  String get obTryOwn;

  /// No description provided for @obTypePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pay rent on the 1st every month'**
  String get obTypePlaceholder;

  /// No description provided for @actionSaveThis.
  ///
  /// In en, this message translates to:
  /// **'Save this'**
  String get actionSaveThis;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionSkipStep.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkipStep;

  /// No description provided for @obBellBirthday.
  ///
  /// In en, this message translates to:
  /// **'Ooh, a birthday. Got it.'**
  String get obBellBirthday;

  /// No description provided for @obNudgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Nudged before it matters.'**
  String get obNudgeTitle;

  /// No description provided for @obNudgeSub.
  ///
  /// In en, this message translates to:
  /// **'Drag through the week. For big days, you get a heads-up early — not just on the day.'**
  String get obNudgeSub;

  /// No description provided for @obDragHint.
  ///
  /// In en, this message translates to:
  /// **'Drag me →'**
  String get obDragHint;

  /// No description provided for @obPreparedNote.
  ///
  /// In en, this message translates to:
  /// **'Prepared? We\'ll stop the early nudges.'**
  String get obPreparedNote;

  /// No description provided for @obScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Your schedule'**
  String get obScheduleTitle;

  /// No description provided for @obScheduleSub.
  ///
  /// In en, this message translates to:
  /// **'We picked sensible defaults. Change anything you like.'**
  String get obScheduleSub;

  /// No description provided for @rowTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get rowTimeZone;

  /// No description provided for @rowDateOnlyAt.
  ///
  /// In en, this message translates to:
  /// **'Date-only reminders at'**
  String get rowDateOnlyAt;

  /// No description provided for @rowDateOnlyAtSub.
  ///
  /// In en, this message translates to:
  /// **'For things without a time, like \"pay rent on the 1st\"'**
  String get rowDateOnlyAtSub;

  /// No description provided for @rowNagHours.
  ///
  /// In en, this message translates to:
  /// **'Repeat reminders between'**
  String get rowNagHours;

  /// No description provided for @rowNagHoursSub.
  ///
  /// In en, this message translates to:
  /// **'We only nag you during these hours'**
  String get rowNagHoursSub;

  /// No description provided for @rowTomorrowMeans.
  ///
  /// In en, this message translates to:
  /// **'\"Tomorrow\" means'**
  String get rowTomorrowMeans;

  /// No description provided for @tomorrowSameTime.
  ///
  /// In en, this message translates to:
  /// **'Same time tomorrow'**
  String get tomorrowSameTime;

  /// No description provided for @actionLooksGood.
  ///
  /// In en, this message translates to:
  /// **'Looks good'**
  String get actionLooksGood;

  /// No description provided for @obCalTitle.
  ///
  /// In en, this message translates to:
  /// **'See your calendar here too'**
  String get obCalTitle;

  /// No description provided for @obCalSub.
  ///
  /// In en, this message translates to:
  /// **'Your events show up next to your reminders. Read-only — we\'ll never change your calendar, and events won\'t ring unless you ask.'**
  String get obCalSub;

  /// No description provided for @actionConnectCalendar.
  ///
  /// In en, this message translates to:
  /// **'Connect calendar'**
  String get actionConnectCalendar;

  /// No description provided for @actionNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get actionNotNow;

  /// No description provided for @obPickCalTitle.
  ///
  /// In en, this message translates to:
  /// **'Which calendars?'**
  String get obPickCalTitle;

  /// No description provided for @obPickCalSub.
  ///
  /// In en, this message translates to:
  /// **'You can change this anytime in Settings.'**
  String get obPickCalSub;

  /// No description provided for @obContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Never miss a birthday'**
  String get obContactsTitle;

  /// No description provided for @obContactsSub.
  ///
  /// In en, this message translates to:
  /// **'Add birthdays and anniversaries from your contacts. Only the dates are used — nothing leaves your phone.'**
  String get obContactsSub;

  /// No description provided for @actionAddBirthdays.
  ///
  /// In en, this message translates to:
  /// **'Add birthdays'**
  String get actionAddBirthdays;

  /// No description provided for @actionImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get actionImport;

  /// No description provided for @obBellParty.
  ///
  /// In en, this message translates to:
  /// **'Party planning starts now.'**
  String get obBellParty;

  /// No description provided for @testTitle.
  ///
  /// In en, this message translates to:
  /// **'Want to make sure it works?'**
  String get testTitle;

  /// No description provided for @testSub.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a test reminder in 15 seconds. Lock your phone to try it for real.'**
  String get testSub;

  /// No description provided for @actionSendTest.
  ///
  /// In en, this message translates to:
  /// **'Send test reminder'**
  String get actionSendTest;

  /// No description provided for @testNotifTitle.
  ///
  /// In en, this message translates to:
  /// **'Test reminder'**
  String get testNotifTitle;

  /// No description provided for @testNotifBody.
  ///
  /// In en, this message translates to:
  /// **'It works! 🔔'**
  String get testNotifBody;

  /// No description provided for @testOk.
  ///
  /// In en, this message translates to:
  /// **'Reminders are working'**
  String get testOk;

  /// No description provided for @testFail.
  ///
  /// In en, this message translates to:
  /// **'The test didn\'t arrive'**
  String get testFail;

  /// No description provided for @testWaiting.
  ///
  /// In en, this message translates to:
  /// **'Test reminder on its way…'**
  String get testWaiting;

  /// No description provided for @testFixExact.
  ///
  /// In en, this message translates to:
  /// **'Turn on precise timing.'**
  String get testFixExact;

  /// No description provided for @testFixBattery.
  ///
  /// In en, this message translates to:
  /// **'Let the app run in the background.'**
  String get testFixBattery;

  /// No description provided for @testSteps.
  ///
  /// In en, this message translates to:
  /// **'Let\'s fix it: check notifications, precise timing, battery optimization and Do Not Disturb.'**
  String get testSteps;

  /// No description provided for @notifTitle.
  ///
  /// In en, this message translates to:
  /// **'Let us ring the bell'**
  String get notifTitle;

  /// No description provided for @notifSub.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications so your reminders reach you on time.'**
  String get notifSub;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @exactTitle.
  ///
  /// In en, this message translates to:
  /// **'Right on time'**
  String get exactTitle;

  /// No description provided for @exactSub.
  ///
  /// In en, this message translates to:
  /// **'Allow \"Alarms & reminders\" so alerts arrive on the minute, not up to 10 minutes late.'**
  String get exactSub;

  /// No description provided for @actionOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get actionOpenSettings;

  /// No description provided for @batteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep reminders reliable'**
  String get batteryTitle;

  /// No description provided for @actionLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get actionLater;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @secSchedule.
  ///
  /// In en, this message translates to:
  /// **'Your schedule'**
  String get secSchedule;

  /// No description provided for @secTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get secTimeZone;

  /// No description provided for @secDefaultAlerts.
  ///
  /// In en, this message translates to:
  /// **'Default alerts'**
  String get secDefaultAlerts;

  /// No description provided for @secNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications & digest'**
  String get secNotifications;

  /// No description provided for @secCalendars.
  ///
  /// In en, this message translates to:
  /// **'Calendars & contacts'**
  String get secCalendars;

  /// No description provided for @secViews.
  ///
  /// In en, this message translates to:
  /// **'Views & appearance'**
  String get secViews;

  /// No description provided for @secReliability.
  ///
  /// In en, this message translates to:
  /// **'Reliability'**
  String get secReliability;

  /// No description provided for @secBackup.
  ///
  /// In en, this message translates to:
  /// **'Backup & about'**
  String get secBackup;

  /// No description provided for @setDefaultZone.
  ///
  /// In en, this message translates to:
  /// **'Default time zone'**
  String get setDefaultZone;

  /// No description provided for @setDefaultZoneDesc.
  ///
  /// In en, this message translates to:
  /// **'New reminders use this time zone.'**
  String get setDefaultZoneDesc;

  /// No description provided for @setAskTravel.
  ///
  /// In en, this message translates to:
  /// **'Ask when I travel'**
  String get setAskTravel;

  /// No description provided for @setAskTravelDesc.
  ///
  /// In en, this message translates to:
  /// **'Offer to switch time zones when you\'re somewhere new.'**
  String get setAskTravelDesc;

  /// No description provided for @setDayTime.
  ///
  /// In en, this message translates to:
  /// **'Date-only reminders at'**
  String get setDayTime;

  /// No description provided for @setDayTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'Alert time for reminders without a time.'**
  String get setDayTimeDesc;

  /// No description provided for @setNagHours.
  ///
  /// In en, this message translates to:
  /// **'Nag hours'**
  String get setNagHours;

  /// No description provided for @setNagHoursDesc.
  ///
  /// In en, this message translates to:
  /// **'Repeat alerts only between these times.'**
  String get setNagHoursDesc;

  /// No description provided for @setTomorrow.
  ///
  /// In en, this message translates to:
  /// **'\"Tomorrow\" means'**
  String get setTomorrow;

  /// No description provided for @setTomorrowDesc.
  ///
  /// In en, this message translates to:
  /// **'When \"Tomorrow\" on a notification brings it back.'**
  String get setTomorrowDesc;

  /// No description provided for @setLateAlerts.
  ///
  /// In en, this message translates to:
  /// **'Late alerts'**
  String get setLateAlerts;

  /// No description provided for @setLateAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'If your phone was off, still show alerts up to this late.'**
  String get setLateAlertsDesc;

  /// No description provided for @late30m.
  ///
  /// In en, this message translates to:
  /// **'30 min'**
  String get late30m;

  /// No description provided for @late2h.
  ///
  /// In en, this message translates to:
  /// **'2 hours'**
  String get late2h;

  /// No description provided for @late6h.
  ///
  /// In en, this message translates to:
  /// **'6 hours'**
  String get late6h;

  /// No description provided for @lateAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get lateAlways;

  /// No description provided for @setDigestTime.
  ///
  /// In en, this message translates to:
  /// **'Digest time'**
  String get setDigestTime;

  /// No description provided for @setDigestTimeDesc.
  ///
  /// In en, this message translates to:
  /// **'When your daily summary arrives.'**
  String get setDigestTimeDesc;

  /// No description provided for @setDigestNotif.
  ///
  /// In en, this message translates to:
  /// **'Digest notification'**
  String get setDigestNotif;

  /// No description provided for @setDigestNotifDesc.
  ///
  /// In en, this message translates to:
  /// **'Get a notification when your digest is ready.'**
  String get setDigestNotifDesc;

  /// No description provided for @setDefaultAlertsDesc.
  ///
  /// In en, this message translates to:
  /// **'Alerts new reminders start with, by type.'**
  String get setDefaultAlertsDesc;

  /// No description provided for @resetDefault.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get resetDefault;

  /// No description provided for @setSounds.
  ///
  /// In en, this message translates to:
  /// **'Completion sounds'**
  String get setSounds;

  /// No description provided for @setSoundsDesc.
  ///
  /// In en, this message translates to:
  /// **'Play a sound when you complete a reminder.'**
  String get setSoundsDesc;

  /// No description provided for @setStartIn.
  ///
  /// In en, this message translates to:
  /// **'Start in'**
  String get setStartIn;

  /// No description provided for @startLast.
  ///
  /// In en, this message translates to:
  /// **'Last used'**
  String get startLast;

  /// No description provided for @setShowCompleted.
  ///
  /// In en, this message translates to:
  /// **'Show completed in calendar views'**
  String get setShowCompleted;

  /// No description provided for @setTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get setTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @relNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get relNotifications;

  /// No description provided for @relPrecise.
  ///
  /// In en, this message translates to:
  /// **'Precise timing'**
  String get relPrecise;

  /// No description provided for @relBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery optimization'**
  String get relBattery;

  /// No description provided for @relOn.
  ///
  /// In en, this message translates to:
  /// **'On'**
  String get relOn;

  /// No description provided for @relOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get relOff;

  /// No description provided for @relBatteryOn.
  ///
  /// In en, this message translates to:
  /// **'On (may delay reminders)'**
  String get relBatteryOn;

  /// No description provided for @zoneDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Change default time zone?'**
  String get zoneDialogTitle;

  /// No description provided for @zoneOnlyNew.
  ///
  /// In en, this message translates to:
  /// **'Only new reminders'**
  String get zoneOnlyNew;

  /// No description provided for @zoneMoveUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Also move upcoming reminders'**
  String get zoneMoveUpcoming;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @calDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect calendar'**
  String get calDisconnect;

  /// No description provided for @calPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Calendar access is off'**
  String get calPermissionOff;

  /// No description provided for @contactsBirthdays.
  ///
  /// In en, this message translates to:
  /// **'Contact birthdays'**
  String get contactsBirthdays;

  /// No description provided for @setAutoAdd.
  ///
  /// In en, this message translates to:
  /// **'Auto-add new birthdays'**
  String get setAutoAdd;

  /// No description provided for @setAutoAddDesc.
  ///
  /// In en, this message translates to:
  /// **'New birthdays in your contacts are added automatically.'**
  String get setAutoAddDesc;

  /// No description provided for @contactsReview.
  ///
  /// In en, this message translates to:
  /// **'Review birthdays'**
  String get contactsReview;

  /// No description provided for @backupExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get backupExport;

  /// No description provided for @backupImport.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get backupImport;

  /// No description provided for @backupBadFile.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a Reminder App backup.'**
  String get backupBadFile;

  /// No description provided for @backupExported.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupExported;

  /// No description provided for @aboutPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get aboutPrivacy;

  /// No description provided for @aboutFeedback.
  ///
  /// In en, this message translates to:
  /// **'Send feedback'**
  String get aboutFeedback;

  /// No description provided for @privacyText.
  ///
  /// In en, this message translates to:
  /// **'Your reminders stay on this phone. Reminder App has no account and no server in this version: nothing you type, no calendar event and no contact leaves your device. Backups are files you save yourself.'**
  String get privacyText;

  /// No description provided for @errVoice.
  ///
  /// In en, this message translates to:
  /// **'Voice input isn\'t available on this phone.'**
  String get errVoice;

  /// No description provided for @errSpeech.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t catch that. Try again?'**
  String get errSpeech;

  /// No description provided for @errSave.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save. Please try again.'**
  String get errSave;

  /// No description provided for @errCalendar.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your calendar. Pull to retry.'**
  String get errCalendar;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @tplBirthday.
  ///
  /// In en, this message translates to:
  /// **'Birthday'**
  String get tplBirthday;

  /// No description provided for @tplBill.
  ///
  /// In en, this message translates to:
  /// **'Bill due'**
  String get tplBill;

  /// No description provided for @tplRenewal.
  ///
  /// In en, this message translates to:
  /// **'Renewal'**
  String get tplRenewal;

  /// No description provided for @tplTrial.
  ///
  /// In en, this message translates to:
  /// **'Free trial'**
  String get tplTrial;

  /// No description provided for @tplNightOut.
  ///
  /// In en, this message translates to:
  /// **'Night out'**
  String get tplNightOut;

  /// No description provided for @tplAppointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get tplAppointment;

  /// No description provided for @tplPhBirthday.
  ///
  /// In en, this message translates to:
  /// **'Whose birthday? When?'**
  String get tplPhBirthday;

  /// No description provided for @tplPhBill.
  ///
  /// In en, this message translates to:
  /// **'Which bill? Due on the…'**
  String get tplPhBill;

  /// No description provided for @tplPhRenewal.
  ///
  /// In en, this message translates to:
  /// **'What renews? When?'**
  String get tplPhRenewal;

  /// No description provided for @tplPhTrial.
  ///
  /// In en, this message translates to:
  /// **'Which trial?'**
  String get tplPhTrial;

  /// No description provided for @tplPhNightOut.
  ///
  /// In en, this message translates to:
  /// **'Where and when?'**
  String get tplPhNightOut;

  /// No description provided for @tplPhAppointment.
  ///
  /// In en, this message translates to:
  /// **'What and when?'**
  String get tplPhAppointment;

  /// No description provided for @actionSpeak.
  ///
  /// In en, this message translates to:
  /// **'Speak'**
  String get actionSpeak;

  /// No description provided for @listening.
  ///
  /// In en, this message translates to:
  /// **'Listening…'**
  String get listening;

  /// No description provided for @sharedSaved.
  ///
  /// In en, this message translates to:
  /// **'Reminder saved'**
  String get sharedSaved;

  /// No description provided for @widgetEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing coming up'**
  String get widgetEmpty;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// S-31 calendar event source
  ///
  /// In en, this message translates to:
  /// **'From {calendar}'**
  String detailFromCalendar(String calendar);

  /// TIM-6 original zone
  ///
  /// In en, this message translates to:
  /// **'{time} in {city}'**
  String zoneNote(String time, String city);

  /// copy.md snackbar
  ///
  /// In en, this message translates to:
  /// **'Rescheduled to {when}'**
  String snackRescheduled(String when);

  /// FL-14
  ///
  /// In en, this message translates to:
  /// **'Done · Next: {date}'**
  String snackNext(String date);

  /// FL-14
  ///
  /// In en, this message translates to:
  /// **'Skipped · Next: {date}'**
  String snackSkippedNext(String date);

  /// Repeat summary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} other{Every {count} days}}'**
  String everyDays(int count);

  /// Repeat summary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every week} other{Every {count} weeks}}'**
  String everyWeeks(int count);

  /// Repeat summary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every month} other{Every {count} months}}'**
  String everyMonths(int count);

  /// Repeat summary
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every year} other{Every {count} years}}'**
  String everyYears(int count);

  /// Repeat summary, e.g. Every Monday
  ///
  /// In en, this message translates to:
  /// **'Every {weekday}'**
  String everyWeekday(String weekday);

  /// Repeat summary
  ///
  /// In en, this message translates to:
  /// **'Every month on the {nth}'**
  String monthlyOnDay(String nth);

  /// Nag interval, e.g. Every 2 hours
  ///
  /// In en, this message translates to:
  /// **'Every {interval}'**
  String nagEvery(String interval);

  /// Day view (copy.md §5)
  ///
  /// In en, this message translates to:
  /// **'Overdue ({count})'**
  String overdueCount(int count);

  /// Month view
  ///
  /// In en, this message translates to:
  /// **'+{count} more'**
  String moreCount(int count);

  /// G7
  ///
  /// In en, this message translates to:
  /// **'No matches for \"{query}\"'**
  String searchEmpty(String query);

  /// G7 button
  ///
  /// In en, this message translates to:
  /// **'Create \"{query}\"'**
  String searchCreate(String query);

  /// DIG-2
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 alert wasn\'t shown} other{{count} alerts weren\'t shown}}'**
  String digestMissedCount(int count);

  /// PRF-5 option
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at {time}'**
  String tomorrowAtTime(String time);

  /// CON-3
  ///
  /// In en, this message translates to:
  /// **'{birthdays} birthdays, {anniversaries} anniversaries found'**
  String contactsFound(int birthdays, int anniversaries);

  /// PRM-7
  ///
  /// In en, this message translates to:
  /// **'Arrived {seconds} seconds late'**
  String testLate(int seconds);

  /// S-07
  ///
  /// In en, this message translates to:
  /// **'Your {brand} phone may pause apps to save battery. One quick setting keeps your reminders on time.'**
  String batterySub(String brand);

  /// S-57
  ///
  /// In en, this message translates to:
  /// **'Last test: {result}'**
  String relLastTest(String result);

  /// FL-16
  ///
  /// In en, this message translates to:
  /// **'{count} upcoming reminders will keep their clock time in {zone}.'**
  String zoneConfirm(int count, String zone);

  /// FL-17
  ///
  /// In en, this message translates to:
  /// **'{total} reminders found · {newer} newer than yours · {same} already here'**
  String backupSummary(int total, int newer, int same);

  /// FL-17
  ///
  /// In en, this message translates to:
  /// **'Imported {count} reminders.'**
  String backupImported(int count);

  /// S-58
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String aboutVersion(String version);

  /// Time range
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String timeRange(String start, String end);

  /// copy.md notif.digest part
  ///
  /// In en, this message translates to:
  /// **'{count} overdue'**
  String digestPartOverdue(int count);

  /// copy.md notif.digest part
  ///
  /// In en, this message translates to:
  /// **'{count} coming up'**
  String digestPartComing(int count);

  /// copy.md notif.travel (TIM-8)
  ///
  /// In en, this message translates to:
  /// **'You\'re in {city}'**
  String travelTitle(String city);

  /// No description provided for @travelBody.
  ///
  /// In en, this message translates to:
  /// **'Switch your default time zone?'**
  String get travelBody;

  /// No description provided for @actionSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get actionSwitch;

  /// No description provided for @actionKeepCity.
  ///
  /// In en, this message translates to:
  /// **'Keep {city}'**
  String actionKeepCity(String city);

  /// copy.md drawer — calendars filtered out
  ///
  /// In en, this message translates to:
  /// **'{count} hidden'**
  String drawerCalendarsHidden(int count);

  /// copy.md §6 detail status card
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {time}'**
  String stateSnoozedUntil(String time);

  /// copy.md §4 — under the input when shared text went to notes (CAP-12)
  ///
  /// In en, this message translates to:
  /// **'Shared text and links saved in notes'**
  String get captureSharedInNotes;

  /// copy.md §8 S-58
  ///
  /// In en, this message translates to:
  /// **'Reminder App feedback ({version})'**
  String feedbackSubject(String version);

  /// copy.md §8 S-58 — no reminder content
  ///
  /// In en, this message translates to:
  /// **'Tell us what happened or what you\'d like to see:\n\n\n\n—\nApp {version} · {device}'**
  String feedbackBody(String version, String device);

  /// copy.md §8 S-58
  ///
  /// In en, this message translates to:
  /// **'No email app found. Write to us at {email}.'**
  String feedbackNoMailApp(String email);

  /// copy.md §8 S-58
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get aboutLicenses;

  /// copy.md §5 — Compact duration, e.g. nag chip "Every 2h"
  ///
  /// In en, this message translates to:
  /// **'{count}h'**
  String hoursShort(int count);

  /// copy.md §5 — Compact duration
  ///
  /// In en, this message translates to:
  /// **'{count}m'**
  String minutesShort(int count);

  /// copy.md §5 — Row subline for overdue items: "Due yesterday", "Due Sat"
  ///
  /// In en, this message translates to:
  /// **'Due {when}'**
  String dueWhen(String when);

  /// copy.md §5 — Inside "Due yesterday"
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get dayYesterday;

  /// copy.md §5 — Right side of the Overdue header when something nags
  ///
  /// In en, this message translates to:
  /// **'Nagging'**
  String get sectionNagging;

  /// copy.md §5 — Right side of the Today header
  ///
  /// In en, this message translates to:
  /// **'{count} done'**
  String sectionDoneCount(int count);

  /// copy.md §5 — Small label inside the daily progress ring
  ///
  /// In en, this message translates to:
  /// **'done'**
  String get ringDone;

  /// copy.md §5 — Home card label
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get upNext;

  /// copy.md §5 — Countdown pill: "in 45 min", "in 6 days"
  ///
  /// In en, this message translates to:
  /// **'in {time}'**
  String inTime(String time);

  /// copy.md §5 — Schedule filter chip
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// copy.md §5 — Schedule filter chip
  ///
  /// In en, this message translates to:
  /// **'Occasions'**
  String get filterOccasions;

  /// copy.md §5 — Schedule filter chip
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get filterEvents;

  /// copy.md §5 — Schedule filter chip
  ///
  /// In en, this message translates to:
  /// **'Meetings'**
  String get filterMeetings;

  /// copy.md §4 capture caption
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get captureDetails;

  /// copy.md §4 line under the capture rows
  ///
  /// In en, this message translates to:
  /// **'First alert {when}'**
  String captureFirstAlert(String when);

  /// copy.md §4 next to the template tag
  ///
  /// In en, this message translates to:
  /// **'Understood from your text'**
  String get captureUnderstood;

  /// copy.md §4 removable template tag
  ///
  /// In en, this message translates to:
  /// **'{name} template'**
  String templateTag(String name);

  /// copy.md §4 Nag subtitle: "Every 2 hours, 8 AM – 10 PM"
  ///
  /// In en, this message translates to:
  /// **'{every}, {range}'**
  String nagEveryBetween(String every, String range);

  /// copy.md §4 alert summary for a date-only item at its day ("1 week, 1 day, on the day")
  ///
  /// In en, this message translates to:
  /// **'on the day'**
  String get alertOnTheDay;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
