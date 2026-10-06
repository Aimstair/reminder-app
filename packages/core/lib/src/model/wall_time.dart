/// Wall-clock time text format shared by the parser, storage and planner.
/// `YYYY-MM-DDTHH:mm` for datetime, `YYYY-MM-DD` for date-only. DateTimes are UTC containers.
library;

String _two(int n) => n.toString().padLeft(2, '0');

String formatWallDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

String formatWallDateTime(DateTime d) => '${formatWallDate(d)}T${_two(d.hour)}:${_two(d.minute)}';

final _re = RegExp(r'^(\d{4})-(\d{2})-(\d{2})(?:T(\d{2}):(\d{2}))?$');

/// Parses either format into a UTC container. Throws [FormatException] on anything else.
DateTime parseWall(String s) {
  final m = _re.firstMatch(s);
  if (m == null) throw FormatException('Bad wall time "$s"');
  return DateTime.utc(
    int.parse(m.group(1)!),
    int.parse(m.group(2)!),
    int.parse(m.group(3)!),
    int.parse(m.group(4) ?? '0'),
    int.parse(m.group(5) ?? '0'),
  );
}
