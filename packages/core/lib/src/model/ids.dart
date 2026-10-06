import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// DAT-4: ids are UUID v7 (time-ordered), generated on device.
String newId() => _uuid.v7();
