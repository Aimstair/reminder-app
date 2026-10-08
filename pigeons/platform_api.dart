// Pigeon definition for the Dart ↔ Kotlin platform bridge: device calendar (CAL-*), share target
// (S-63), launch actions from the Quick Settings tile / widget / notifications (S-61, S-62, NTF-3),
// backup files (DAT-5) and the home-screen widget.
// Regenerate: dart run pigeon --input pigeons/platform_api.dart
import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/native/platform_api.g.dart',
  kotlinOut:
      'android/app/src/main/kotlin/app/aimstair/reminder_app/platform/PlatformApi.g.kt',
  kotlinOptions: KotlinOptions(package: 'app.aimstair.reminder_app.platform'),
  dartPackageName: 'reminder_app',
))

/// A calendar on the device (S-04 picker).
class DeviceCalendar {
  DeviceCalendar({
    required this.id,
    required this.name,
    required this.color,
    required this.accountName,
    required this.isBirthdays,
  });

  String id;
  String name;

  /// ARGB.
  int color;
  String accountName;

  /// The contacts/"Birthdays" calendar (CAL-4 rule 1, CON-7).
  bool isBirthdays;
}

/// One event instance from CalendarContract.Instances.
class DeviceEvent {
  DeviceEvent({
    required this.calendarId,
    required this.eventId,
    required this.title,
    required this.beginMs,
    required this.endMs,
    required this.allDay,
    required this.timeZone,
    required this.rrule,
    required this.otherAttendees,
  });

  String calendarId;
  String eventId;
  String title;
  int beginMs;
  int endMs;
  bool allDay;
  String? timeZone;
  String? rrule;

  /// Attendees other than the calendar's owner (CAL-4 rule 3).
  int otherAttendees;
}

@HostApi()
abstract class PlatformHostApi {
  bool hasCalendarPermission();

  @async
  bool requestCalendarPermission();

  List<DeviceCalendar> readCalendars();

  List<DeviceEvent> readEvents(int fromMs, int toMs, List<String> calendarIds);

  /// S-63: pending shared text, returned once.
  String? takeSharedText();

  /// Pending launch action, returned once: `capture` or `open:<alarmKey>`.
  String? takeLaunchAction();

  /// DAT-5: save a backup through the system file picker; null if cancelled.
  @async
  String? saveBackup(String fileName, String json);

  /// DAT-5: pick a backup file and return its text; null if cancelled.
  @async
  String? openBackup();

  /// S-61: JSON `{"items":[{"title","when"}],"empty":"…"}` for the home-screen widget.
  void updateWidget(String json);

  /// PRM-4: Build.MANUFACTURER for the battery tip.
  String deviceBrand();

  /// S-58 feedback email footer: "samsung SM-A736B · Android 15 (API 35)". Device info only.
  String deviceInfo();

  /// Opens the system share sheet with [text] (All clear "share", mockup 10). Only what the user sees.
  void shareText(String text);
}

@FlutterApi()
abstract class PlatformFlutterApi {
  void onSharedText(String text);

  void onLaunchAction(String action);
}
