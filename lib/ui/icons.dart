/// App icons: Phosphor (design-direction.md §3, decided 2026-10-08), MIT — fonts vendored in
/// assets/fonts (the phosphor_flutter package doesn't build on current Flutter). One place to swap the set.
/// Regular weight for line icons; Fill only where a solid shape is meant (status ticks, dots).
library;

import 'package:flutter/widgets.dart';

abstract final class AppIcons {
  static const IconData add = IconData(0xe3d4, fontFamily: 'Phosphor'); // plus
  static const IconData alert = IconData(0xe0ce, fontFamily: 'Phosphor'); // bell
  static const IconData alerts = IconData(0xe5e8, fontFamily: 'Phosphor'); // bellRinging
  static const IconData anniversary = IconData(0xe2a8, fontFamily: 'Phosphor'); // heart
  static const IconData appearance = IconData(0xe6c8, fontFamily: 'Phosphor'); // palette
  static const IconData appointment = IconData(0xe570, fontFamily: 'Phosphor'); // firstAidKit
  static const IconData autoAdd = IconData(0xe4d0, fontFamily: 'Phosphor'); // userPlus
  static const IconData backup = IconData(0xe00c, fontFamily: 'Phosphor'); // archive
  static const IconData battery = IconData(0xe0ba, fontFamily: 'Phosphor'); // batteryCharging
  static const IconData bill = IconData(0xe3ec, fontFamily: 'Phosphor'); // receipt
  static const IconData birthday = IconData(0xe780, fontFamily: 'Phosphor'); // cake
  static const IconData calendar = IconData(0xe10a, fontFamily: 'Phosphor'); // calendarBlank
  static const IconData calendarOff = IconData(0xe10c, fontFamily: 'Phosphor'); // calendarX
  static const IconData check = IconData(0xe182, fontFamily: 'Phosphor'); // check
  static const IconData close = IconData(0xe4f6, fontFamily: 'Phosphor'); // x
  static const IconData collapse = IconData(0xe13c, fontFamily: 'Phosphor'); // caretUp
  static const IconData contactRemoved = IconData(0xe4ce, fontFamily: 'Phosphor'); // userMinus
  static const IconData custom = IconData(0xe434, fontFamily: 'Phosphor'); // slidersHorizontal
  static const IconData day = IconData(0xe472, fontFamily: 'Phosphor'); // sun
  static const IconData dayView = IconData(0xe7b2, fontFamily: 'Phosphor'); // calendarDot
  static const IconData delete = IconData(0xe4a6, fontFamily: 'Phosphor'); // trash
  static const IconData diagnostics = IconData(0xe2ac, fontFamily: 'Phosphor'); // heartbeat
  static const IconData digest = IconData(0xe5b6, fontFamily: 'Phosphor'); // sunHorizon
  static const IconData disconnect = IconData(0xe2e4, fontFamily: 'Phosphor'); // linkBreak
  static const IconData done = IconData(0xe184, fontFamily: 'Phosphor'); // checkCircle
  static const IconData dot = IconData(0xe18a, fontFamily: 'PhosphorFill'); // circle
  static const IconData dropDown = IconData(0xe136, fontFamily: 'Phosphor'); // caretDown
  static const IconData edit = IconData(0xe3b4, fontFamily: 'Phosphor'); // pencilSimple
  static const IconData endTime = IconData(0xe2b8, fontFamily: 'Phosphor'); // hourglassMedium
  static const IconData error = IconData(0xe4e2, fontFamily: 'Phosphor'); // warningCircle
  static const IconData evening = IconData(0xe58e, fontFamily: 'Phosphor'); // moonStars
  static const IconData event = IconData(0xe8b2, fontFamily: 'Phosphor'); // calendarStar
  static const IconData expand = IconData(0xe136, fontFamily: 'Phosphor'); // caretDown
  static const IconData exportFile = IconData(0xeaf0, fontFamily: 'Phosphor'); // export
  static const IconData feedback = IconData(0xe168, fontFamily: 'Phosphor'); // chatCircle
  static const IconData gift = IconData(0xe276, fontFamily: 'Phosphor'); // gift
  static const IconData help = IconData(0xe3e8, fontFamily: 'Phosphor'); // question
  static const IconData importFile = IconData(0xe20c, fontFamily: 'Phosphor'); // downloadSimple
  static const IconData info = IconData(0xe2ce, fontFamily: 'Phosphor'); // info
  static const IconData licenses = IconData(0xe23a, fontFamily: 'Phosphor'); // fileText
  static const IconData link = IconData(0xe2e2, fontFamily: 'Phosphor'); // link
  static const IconData meeting = IconData(0xe68e, fontFamily: 'Phosphor'); // usersThree
  static const IconData mic = IconData(0xe326, fontFamily: 'Phosphor'); // microphone
  static const IconData minus = IconData(0xe32a, fontFamily: 'Phosphor'); // minus
  static const IconData monthView = IconData(0xe7b4, fontFamily: 'Phosphor'); // calendarDots
  static const IconData nag = IconData(0xe038, fontFamily: 'Phosphor'); // arrowCounterClockwise
  static const IconData next = IconData(0xe13a, fontFamily: 'Phosphor'); // caretRight
  static const IconData nextWeek = IconData(0xe108, fontFamily: 'Phosphor'); // calendar
  static const IconData night = IconData(0xe330, fontFamily: 'PhosphorFill'); // moon
  static const IconData nightOut = IconData(0xe31c, fontFamily: 'Phosphor'); // martini
  static const IconData notifications = IconData(0xe0ce, fontFamily: 'Phosphor'); // bell
  static const IconData notificationsOff = IconData(0xe0d4, fontFamily: 'Phosphor'); // bellSlash
  static const IconData ok = IconData(0xe184, fontFamily: 'PhosphorFill'); // checkCircle
  static const IconData personal = IconData(0xe4c2, fontFamily: 'Phosphor'); // user
  static const IconData pickDate = IconData(0xe714, fontFamily: 'Phosphor'); // calendarPlus
  static const IconData precise = IconData(0xe492, fontFamily: 'Phosphor'); // timer
  static const IconData preciseOff = IconData(0xe492, fontFamily: 'Phosphor'); // timer
  static const IconData previous = IconData(0xe138, fontFamily: 'Phosphor'); // caretLeft
  static const IconData privacy = IconData(0xe40c, fontFamily: 'Phosphor'); // shieldCheck
  static const IconData reliability = IconData(0xe606, fontFamily: 'Phosphor'); // sealCheck
  static const IconData remove = IconData(0xe32c, fontFamily: 'Phosphor'); // minusCircle
  static const IconData renewal = IconData(0xe094, fontFamily: 'Phosphor'); // arrowsClockwise
  static const IconData repeat = IconData(0xe3f6, fontFamily: 'Phosphor'); // repeat
  static const IconData reschedule = IconData(0xe19e, fontFamily: 'Phosphor'); // clockClockwise
  static const IconData review = IconData(0xeadc, fontFamily: 'Phosphor'); // listChecks
  static const IconData scheduleView = IconData(0xe5a2, fontFamily: 'Phosphor'); // rows
  static const IconData search = IconData(0xe30c, fontFamily: 'Phosphor'); // magnifyingGlass
  static const IconData send = IconData(0xe396, fontFamily: 'Phosphor'); // paperPlaneRight
  static const IconData settings = IconData(0xe270, fontFamily: 'Phosphor'); // gear
  static const IconData skip = IconData(0xe5a6, fontFamily: 'Phosphor'); // skipForward
  static const IconData snooze = IconData(0xe5ee, fontFamily: 'Phosphor'); // bellZ
  static const IconData sound = IconData(0xe33c, fontFamily: 'Phosphor'); // musicNote
  static const IconData stop = IconData(0xe46e, fontFamily: 'PhosphorFill'); // stopCircle
  static const IconData sun = IconData(0xe472, fontFamily: 'PhosphorFill'); // sun
  static const IconData task = IconData(0xe184, fontFamily: 'Phosphor'); // checkCircle
  static const IconData time = IconData(0xe19a, fontFamily: 'Phosphor'); // clock
  static const IconData timeZone = IconData(0xe288, fontFamily: 'Phosphor'); // globe
  static const IconData travel = IconData(0xe504, fontFamily: 'Phosphor'); // airplaneTakeoff
  static const IconData undo = IconData(0xe08a, fontFamily: 'Phosphor'); // arrowUUpLeft
  static const IconData waiting = IconData(0xe2b4, fontFamily: 'Phosphor'); // hourglassHigh
  static const IconData warning = IconData(0xe4e0, fontFamily: 'Phosphor'); // warning
  static const IconData work = IconData(0xe0ee, fontFamily: 'Phosphor'); // briefcase
}
