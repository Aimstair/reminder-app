/// SUB-2: subtype guessed from a reminder's words, within its type.
library;

import '../model/enums.dart';
import '../parser/vocab.dart';

bool _has(String s, List<String> words) =>
    words.any((w) => RegExp('(?<![a-z0-9])${RegExp.escape(w)}(?![a-z0-9])').hasMatch(s));

/// The subtype [title] suggests for [kind]; null when nothing matches (shown as "Other" / the plain type).
SubKind? guessSubKind(Kind kind, String title) {
  final t = title.toLowerCase();
  switch (kind) {
    case Kind.occasion:
      // Memorial first: "Grandpa's death anniversary" is a memorial, not an anniversary.
      if (_has(t, memorialWords) && !_has(t, const ['memorial day'])) return SubKind.memorial;
      if (_has(t, const ['birthday', 'bday'])) return SubKind.birthday;
      if (_has(t, const ['anniversary'])) return SubKind.anniversary;
      if (_has(t, holidayWords)) return SubKind.holiday;
      return null;
    case Kind.meeting:
      if (_has(t, phoneWords)) return SubKind.phone;
      if (_has(t, inPersonWords)) return SubKind.inPerson;
      if (_has(t, videoWords)) return SubKind.video;
      return null;
    case Kind.event:
      if (_has(t, appointmentWords)) return SubKind.appointment;
      if (_has(t, travelWords)) return SubKind.travel;
      if (_has(t, socialWords)) return SubKind.social;
      return null;
    case Kind.task || Kind.bill:
      return null;
  }
}
