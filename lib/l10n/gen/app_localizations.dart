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
