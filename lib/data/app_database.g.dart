// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $RemindersTable extends Reminders with TableInfo<$RemindersTable, ReminderRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RemindersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawInputMeta = const VerificationMeta('rawInput');
  @override
  late final GeneratedColumn<String> rawInput = GeneratedColumn<String>(
    'raw_input',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Kind, String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<Kind>($RemindersTable.$converterkind);
  @override
  late final GeneratedColumnWithTypeConverter<ReminderContext, String> context = GeneratedColumn<String>(
    'context',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ReminderContext>($RemindersTable.$convertercontext);
  @override
  late final GeneratedColumnWithTypeConverter<TimingType, String> timingType = GeneratedColumn<String>(
    'timing_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<TimingType>($RemindersTable.$convertertimingType);
  static const VerificationMeta _startLocalMeta = const VerificationMeta('startLocal');
  @override
  late final GeneratedColumn<String> startLocal = GeneratedColumn<String>(
    'start_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endLocalMeta = const VerificationMeta('endLocal');
  @override
  late final GeneratedColumn<String> endLocal = GeneratedColumn<String>(
    'end_local',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tzMeta = const VerificationMeta('tz');
  @override
  late final GeneratedColumn<String> tz = GeneratedColumn<String>(
    'tz',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tzSetManuallyMeta = const VerificationMeta('tzSetManually');
  @override
  late final GeneratedColumn<bool> tzSetManually = GeneratedColumn<bool>(
    'tz_set_manually',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("tz_set_manually" IN (0, 1))'),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _rruleMeta = const VerificationMeta('rrule');
  @override
  late final GeneratedColumn<String> rrule = GeneratedColumn<String>(
    'rrule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RecurrenceMode, String> repeatMode = GeneratedColumn<String>(
    'repeat_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<RecurrenceMode>($RemindersTable.$converterrepeatMode);
  static const VerificationMeta _alertPlanMeta = const VerificationMeta('alertPlan');
  @override
  late final GeneratedColumn<String> alertPlan = GeneratedColumn<String>(
    'alert_plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nagMinutesMeta = const VerificationMeta('nagMinutes');
  @override
  late final GeneratedColumn<int> nagMinutes = GeneratedColumn<int>(
    'nag_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completableMeta = const VerificationMeta('completable');
  @override
  late final GeneratedColumn<bool> completable = GeneratedColumn<bool>(
    'completable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('CHECK ("completable" IN (0, 1))'),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta('templateId');
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ReminderStatus, String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<ReminderStatus>($RemindersTable.$converterstatus);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deviceId,
    deletedAt,
    title,
    notes,
    rawInput,
    kind,
    context,
    timingType,
    startLocal,
    endLocal,
    tz,
    tzSetManually,
    rrule,
    repeatMode,
    alertPlan,
    nagMinutes,
    completable,
    source,
    templateId,
    status,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reminders';
  @override
  VerificationContext validateIntegrity(Insertable<ReminderRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta, deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('title')) {
      context.handle(_titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(_notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('raw_input')) {
      context.handle(_rawInputMeta, rawInput.isAcceptableOrUnknown(data['raw_input']!, _rawInputMeta));
    }
    if (data.containsKey('start_local')) {
      context.handle(_startLocalMeta, startLocal.isAcceptableOrUnknown(data['start_local']!, _startLocalMeta));
    } else if (isInserting) {
      context.missing(_startLocalMeta);
    }
    if (data.containsKey('end_local')) {
      context.handle(_endLocalMeta, endLocal.isAcceptableOrUnknown(data['end_local']!, _endLocalMeta));
    }
    if (data.containsKey('tz')) {
      context.handle(_tzMeta, tz.isAcceptableOrUnknown(data['tz']!, _tzMeta));
    }
    if (data.containsKey('tz_set_manually')) {
      context.handle(
        _tzSetManuallyMeta,
        tzSetManually.isAcceptableOrUnknown(data['tz_set_manually']!, _tzSetManuallyMeta),
      );
    }
    if (data.containsKey('rrule')) {
      context.handle(_rruleMeta, rrule.isAcceptableOrUnknown(data['rrule']!, _rruleMeta));
    }
    if (data.containsKey('alert_plan')) {
      context.handle(_alertPlanMeta, alertPlan.isAcceptableOrUnknown(data['alert_plan']!, _alertPlanMeta));
    } else if (isInserting) {
      context.missing(_alertPlanMeta);
    }
    if (data.containsKey('nag_minutes')) {
      context.handle(_nagMinutesMeta, nagMinutes.isAcceptableOrUnknown(data['nag_minutes']!, _nagMinutesMeta));
    }
    if (data.containsKey('completable')) {
      context.handle(_completableMeta, completable.isAcceptableOrUnknown(data['completable']!, _completableMeta));
    } else if (isInserting) {
      context.missing(_completableMeta);
    }
    if (data.containsKey('source')) {
      context.handle(_sourceMeta, source.isAcceptableOrUnknown(data['source']!, _sourceMeta));
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(_templateIdMeta, templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReminderRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReminderRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deviceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      title: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      notes: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}notes']),
      rawInput: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}raw_input']),
      kind: $RemindersTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind'])!,
      ),
      context: $RemindersTable.$convertercontext.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}context'])!,
      ),
      timingType: $RemindersTable.$convertertimingType.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}timing_type'])!,
      ),
      startLocal: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}start_local'])!,
      endLocal: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}end_local']),
      tz: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}tz']),
      tzSetManually: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}tz_set_manually'])!,
      rrule: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}rrule']),
      repeatMode: $RemindersTable.$converterrepeatMode.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}repeat_mode'])!,
      ),
      alertPlan: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}alert_plan'])!,
      nagMinutes: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}nag_minutes']),
      completable: attachedDatabase.typeMapping.read(DriftSqlType.bool, data['${effectivePrefix}completable'])!,
      source: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}source'])!,
      templateId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}template_id']),
      status: $RemindersTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      ),
    );
  }

  @override
  $RemindersTable createAlias(String alias) {
    return $RemindersTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Kind, String, String> $converterkind = const EnumNameConverter<Kind>(Kind.values);
  static JsonTypeConverter2<ReminderContext, String, String> $convertercontext =
      const EnumNameConverter<ReminderContext>(ReminderContext.values);
  static JsonTypeConverter2<TimingType, String, String> $convertertimingType = const EnumNameConverter<TimingType>(
    TimingType.values,
  );
  static JsonTypeConverter2<RecurrenceMode, String, String> $converterrepeatMode = const EnumNameConverter<RecurrenceMode>(
    RecurrenceMode.values,
  );
  static JsonTypeConverter2<ReminderStatus, String, String> $converterstatus = const EnumNameConverter<ReminderStatus>(
    ReminderStatus.values,
  );
}

class ReminderRow extends DataClass implements Insertable<ReminderRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceId;
  final DateTime? deletedAt;
  final String title;
  final String? notes;
  final String? rawInput;
  final Kind kind;
  final ReminderContext context;
  final TimingType timingType;
  final String startLocal;
  final String? endLocal;
  final String? tz;
  final bool tzSetManually;
  final String? rrule;
  final RecurrenceMode repeatMode;
  final String alertPlan;
  final int? nagMinutes;
  final bool completable;
  final String source;
  final String? templateId;
  final ReminderStatus status;
  const ReminderRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.deletedAt,
    required this.title,
    this.notes,
    this.rawInput,
    required this.kind,
    required this.context,
    required this.timingType,
    required this.startLocal,
    this.endLocal,
    this.tz,
    required this.tzSetManually,
    this.rrule,
    required this.repeatMode,
    required this.alertPlan,
    this.nagMinutes,
    required this.completable,
    required this.source,
    this.templateId,
    required this.status,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || rawInput != null) {
      map['raw_input'] = Variable<String>(rawInput);
    }
    {
      map['kind'] = Variable<String>($RemindersTable.$converterkind.toSql(kind));
    }
    {
      map['context'] = Variable<String>($RemindersTable.$convertercontext.toSql(context));
    }
    {
      map['timing_type'] = Variable<String>($RemindersTable.$convertertimingType.toSql(timingType));
    }
    map['start_local'] = Variable<String>(startLocal);
    if (!nullToAbsent || endLocal != null) {
      map['end_local'] = Variable<String>(endLocal);
    }
    if (!nullToAbsent || tz != null) {
      map['tz'] = Variable<String>(tz);
    }
    map['tz_set_manually'] = Variable<bool>(tzSetManually);
    if (!nullToAbsent || rrule != null) {
      map['rrule'] = Variable<String>(rrule);
    }
    {
      map['repeat_mode'] = Variable<String>($RemindersTable.$converterrepeatMode.toSql(repeatMode));
    }
    map['alert_plan'] = Variable<String>(alertPlan);
    if (!nullToAbsent || nagMinutes != null) {
      map['nag_minutes'] = Variable<int>(nagMinutes);
    }
    map['completable'] = Variable<bool>(completable);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    {
      map['status'] = Variable<String>($RemindersTable.$converterstatus.toSql(status));
    }
    return map;
  }

  RemindersCompanion toCompanion(bool nullToAbsent) {
    return RemindersCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      title: Value(title),
      notes: notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      rawInput: rawInput == null && nullToAbsent ? const Value.absent() : Value(rawInput),
      kind: Value(kind),
      context: Value(context),
      timingType: Value(timingType),
      startLocal: Value(startLocal),
      endLocal: endLocal == null && nullToAbsent ? const Value.absent() : Value(endLocal),
      tz: tz == null && nullToAbsent ? const Value.absent() : Value(tz),
      tzSetManually: Value(tzSetManually),
      rrule: rrule == null && nullToAbsent ? const Value.absent() : Value(rrule),
      repeatMode: Value(repeatMode),
      alertPlan: Value(alertPlan),
      nagMinutes: nagMinutes == null && nullToAbsent ? const Value.absent() : Value(nagMinutes),
      completable: Value(completable),
      source: Value(source),
      templateId: templateId == null && nullToAbsent ? const Value.absent() : Value(templateId),
      status: Value(status),
    );
  }

  factory ReminderRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReminderRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      rawInput: serializer.fromJson<String?>(json['rawInput']),
      kind: $RemindersTable.$converterkind.fromJson(serializer.fromJson<String>(json['kind'])),
      context: $RemindersTable.$convertercontext.fromJson(serializer.fromJson<String>(json['context'])),
      timingType: $RemindersTable.$convertertimingType.fromJson(serializer.fromJson<String>(json['timingType'])),
      startLocal: serializer.fromJson<String>(json['startLocal']),
      endLocal: serializer.fromJson<String?>(json['endLocal']),
      tz: serializer.fromJson<String?>(json['tz']),
      tzSetManually: serializer.fromJson<bool>(json['tzSetManually']),
      rrule: serializer.fromJson<String?>(json['rrule']),
      repeatMode: $RemindersTable.$converterrepeatMode.fromJson(serializer.fromJson<String>(json['repeatMode'])),
      alertPlan: serializer.fromJson<String>(json['alertPlan']),
      nagMinutes: serializer.fromJson<int?>(json['nagMinutes']),
      completable: serializer.fromJson<bool>(json['completable']),
      source: serializer.fromJson<String>(json['source']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      status: $RemindersTable.$converterstatus.fromJson(serializer.fromJson<String>(json['status'])),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'rawInput': serializer.toJson<String?>(rawInput),
      'kind': serializer.toJson<String>($RemindersTable.$converterkind.toJson(kind)),
      'context': serializer.toJson<String>($RemindersTable.$convertercontext.toJson(context)),
      'timingType': serializer.toJson<String>($RemindersTable.$convertertimingType.toJson(timingType)),
      'startLocal': serializer.toJson<String>(startLocal),
      'endLocal': serializer.toJson<String?>(endLocal),
      'tz': serializer.toJson<String?>(tz),
      'tzSetManually': serializer.toJson<bool>(tzSetManually),
      'rrule': serializer.toJson<String?>(rrule),
      'repeatMode': serializer.toJson<String>($RemindersTable.$converterrepeatMode.toJson(repeatMode)),
      'alertPlan': serializer.toJson<String>(alertPlan),
      'nagMinutes': serializer.toJson<int?>(nagMinutes),
      'completable': serializer.toJson<bool>(completable),
      'source': serializer.toJson<String>(source),
      'templateId': serializer.toJson<String?>(templateId),
      'status': serializer.toJson<String>($RemindersTable.$converterstatus.toJson(status)),
    };
  }

  ReminderRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? title,
    Value<String?> notes = const Value.absent(),
    Value<String?> rawInput = const Value.absent(),
    Kind? kind,
    ReminderContext? context,
    TimingType? timingType,
    String? startLocal,
    Value<String?> endLocal = const Value.absent(),
    Value<String?> tz = const Value.absent(),
    bool? tzSetManually,
    Value<String?> rrule = const Value.absent(),
    RecurrenceMode? repeatMode,
    String? alertPlan,
    Value<int?> nagMinutes = const Value.absent(),
    bool? completable,
    String? source,
    Value<String?> templateId = const Value.absent(),
    ReminderStatus? status,
  }) => ReminderRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    rawInput: rawInput.present ? rawInput.value : this.rawInput,
    kind: kind ?? this.kind,
    context: context ?? this.context,
    timingType: timingType ?? this.timingType,
    startLocal: startLocal ?? this.startLocal,
    endLocal: endLocal.present ? endLocal.value : this.endLocal,
    tz: tz.present ? tz.value : this.tz,
    tzSetManually: tzSetManually ?? this.tzSetManually,
    rrule: rrule.present ? rrule.value : this.rrule,
    repeatMode: repeatMode ?? this.repeatMode,
    alertPlan: alertPlan ?? this.alertPlan,
    nagMinutes: nagMinutes.present ? nagMinutes.value : this.nagMinutes,
    completable: completable ?? this.completable,
    source: source ?? this.source,
    templateId: templateId.present ? templateId.value : this.templateId,
    status: status ?? this.status,
  );
  ReminderRow copyWithCompanion(RemindersCompanion data) {
    return ReminderRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      rawInput: data.rawInput.present ? data.rawInput.value : this.rawInput,
      kind: data.kind.present ? data.kind.value : this.kind,
      context: data.context.present ? data.context.value : this.context,
      timingType: data.timingType.present ? data.timingType.value : this.timingType,
      startLocal: data.startLocal.present ? data.startLocal.value : this.startLocal,
      endLocal: data.endLocal.present ? data.endLocal.value : this.endLocal,
      tz: data.tz.present ? data.tz.value : this.tz,
      tzSetManually: data.tzSetManually.present ? data.tzSetManually.value : this.tzSetManually,
      rrule: data.rrule.present ? data.rrule.value : this.rrule,
      repeatMode: data.repeatMode.present ? data.repeatMode.value : this.repeatMode,
      alertPlan: data.alertPlan.present ? data.alertPlan.value : this.alertPlan,
      nagMinutes: data.nagMinutes.present ? data.nagMinutes.value : this.nagMinutes,
      completable: data.completable.present ? data.completable.value : this.completable,
      source: data.source.present ? data.source.value : this.source,
      templateId: data.templateId.present ? data.templateId.value : this.templateId,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReminderRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('rawInput: $rawInput, ')
          ..write('kind: $kind, ')
          ..write('context: $context, ')
          ..write('timingType: $timingType, ')
          ..write('startLocal: $startLocal, ')
          ..write('endLocal: $endLocal, ')
          ..write('tz: $tz, ')
          ..write('tzSetManually: $tzSetManually, ')
          ..write('rrule: $rrule, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('alertPlan: $alertPlan, ')
          ..write('nagMinutes: $nagMinutes, ')
          ..write('completable: $completable, ')
          ..write('source: $source, ')
          ..write('templateId: $templateId, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    deviceId,
    deletedAt,
    title,
    notes,
    rawInput,
    kind,
    context,
    timingType,
    startLocal,
    endLocal,
    tz,
    tzSetManually,
    rrule,
    repeatMode,
    alertPlan,
    nagMinutes,
    completable,
    source,
    templateId,
    status,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReminderRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deletedAt == this.deletedAt &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.rawInput == this.rawInput &&
          other.kind == this.kind &&
          other.context == this.context &&
          other.timingType == this.timingType &&
          other.startLocal == this.startLocal &&
          other.endLocal == this.endLocal &&
          other.tz == this.tz &&
          other.tzSetManually == this.tzSetManually &&
          other.rrule == this.rrule &&
          other.repeatMode == this.repeatMode &&
          other.alertPlan == this.alertPlan &&
          other.nagMinutes == this.nagMinutes &&
          other.completable == this.completable &&
          other.source == this.source &&
          other.templateId == this.templateId &&
          other.status == this.status);
}

class RemindersCompanion extends UpdateCompanion<ReminderRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<DateTime?> deletedAt;
  final Value<String> title;
  final Value<String?> notes;
  final Value<String?> rawInput;
  final Value<Kind> kind;
  final Value<ReminderContext> context;
  final Value<TimingType> timingType;
  final Value<String> startLocal;
  final Value<String?> endLocal;
  final Value<String?> tz;
  final Value<bool> tzSetManually;
  final Value<String?> rrule;
  final Value<RecurrenceMode> repeatMode;
  final Value<String> alertPlan;
  final Value<int?> nagMinutes;
  final Value<bool> completable;
  final Value<String> source;
  final Value<String?> templateId;
  final Value<ReminderStatus> status;
  final Value<int> rowid;
  const RemindersCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.rawInput = const Value.absent(),
    this.kind = const Value.absent(),
    this.context = const Value.absent(),
    this.timingType = const Value.absent(),
    this.startLocal = const Value.absent(),
    this.endLocal = const Value.absent(),
    this.tz = const Value.absent(),
    this.tzSetManually = const Value.absent(),
    this.rrule = const Value.absent(),
    this.repeatMode = const Value.absent(),
    this.alertPlan = const Value.absent(),
    this.nagMinutes = const Value.absent(),
    this.completable = const Value.absent(),
    this.source = const Value.absent(),
    this.templateId = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RemindersCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String deviceId,
    this.deletedAt = const Value.absent(),
    required String title,
    this.notes = const Value.absent(),
    this.rawInput = const Value.absent(),
    required Kind kind,
    required ReminderContext context,
    required TimingType timingType,
    required String startLocal,
    this.endLocal = const Value.absent(),
    this.tz = const Value.absent(),
    this.tzSetManually = const Value.absent(),
    this.rrule = const Value.absent(),
    required RecurrenceMode repeatMode,
    required String alertPlan,
    this.nagMinutes = const Value.absent(),
    required bool completable,
    required String source,
    this.templateId = const Value.absent(),
    required ReminderStatus status,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       title = Value(title),
       kind = Value(kind),
       context = Value(context),
       timingType = Value(timingType),
       startLocal = Value(startLocal),
       repeatMode = Value(repeatMode),
       alertPlan = Value(alertPlan),
       completable = Value(completable),
       source = Value(source),
       status = Value(status);
  static Insertable<ReminderRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? deletedAt,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? rawInput,
    Expression<String>? kind,
    Expression<String>? context,
    Expression<String>? timingType,
    Expression<String>? startLocal,
    Expression<String>? endLocal,
    Expression<String>? tz,
    Expression<bool>? tzSetManually,
    Expression<String>? rrule,
    Expression<String>? repeatMode,
    Expression<String>? alertPlan,
    Expression<int>? nagMinutes,
    Expression<bool>? completable,
    Expression<String>? source,
    Expression<String>? templateId,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (rawInput != null) 'raw_input': rawInput,
      if (kind != null) 'kind': kind,
      if (context != null) 'context': context,
      if (timingType != null) 'timing_type': timingType,
      if (startLocal != null) 'start_local': startLocal,
      if (endLocal != null) 'end_local': endLocal,
      if (tz != null) 'tz': tz,
      if (tzSetManually != null) 'tz_set_manually': tzSetManually,
      if (rrule != null) 'rrule': rrule,
      if (repeatMode != null) 'repeat_mode': repeatMode,
      if (alertPlan != null) 'alert_plan': alertPlan,
      if (nagMinutes != null) 'nag_minutes': nagMinutes,
      if (completable != null) 'completable': completable,
      if (source != null) 'source': source,
      if (templateId != null) 'template_id': templateId,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RemindersCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<DateTime?>? deletedAt,
    Value<String>? title,
    Value<String?>? notes,
    Value<String?>? rawInput,
    Value<Kind>? kind,
    Value<ReminderContext>? context,
    Value<TimingType>? timingType,
    Value<String>? startLocal,
    Value<String?>? endLocal,
    Value<String?>? tz,
    Value<bool>? tzSetManually,
    Value<String?>? rrule,
    Value<RecurrenceMode>? repeatMode,
    Value<String>? alertPlan,
    Value<int?>? nagMinutes,
    Value<bool>? completable,
    Value<String>? source,
    Value<String?>? templateId,
    Value<ReminderStatus>? status,
    Value<int>? rowid,
  }) {
    return RemindersCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deletedAt: deletedAt ?? this.deletedAt,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      rawInput: rawInput ?? this.rawInput,
      kind: kind ?? this.kind,
      context: context ?? this.context,
      timingType: timingType ?? this.timingType,
      startLocal: startLocal ?? this.startLocal,
      endLocal: endLocal ?? this.endLocal,
      tz: tz ?? this.tz,
      tzSetManually: tzSetManually ?? this.tzSetManually,
      rrule: rrule ?? this.rrule,
      repeatMode: repeatMode ?? this.repeatMode,
      alertPlan: alertPlan ?? this.alertPlan,
      nagMinutes: nagMinutes ?? this.nagMinutes,
      completable: completable ?? this.completable,
      source: source ?? this.source,
      templateId: templateId ?? this.templateId,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (rawInput.present) {
      map['raw_input'] = Variable<String>(rawInput.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>($RemindersTable.$converterkind.toSql(kind.value));
    }
    if (context.present) {
      map['context'] = Variable<String>($RemindersTable.$convertercontext.toSql(context.value));
    }
    if (timingType.present) {
      map['timing_type'] = Variable<String>($RemindersTable.$convertertimingType.toSql(timingType.value));
    }
    if (startLocal.present) {
      map['start_local'] = Variable<String>(startLocal.value);
    }
    if (endLocal.present) {
      map['end_local'] = Variable<String>(endLocal.value);
    }
    if (tz.present) {
      map['tz'] = Variable<String>(tz.value);
    }
    if (tzSetManually.present) {
      map['tz_set_manually'] = Variable<bool>(tzSetManually.value);
    }
    if (rrule.present) {
      map['rrule'] = Variable<String>(rrule.value);
    }
    if (repeatMode.present) {
      map['repeat_mode'] = Variable<String>($RemindersTable.$converterrepeatMode.toSql(repeatMode.value));
    }
    if (alertPlan.present) {
      map['alert_plan'] = Variable<String>(alertPlan.value);
    }
    if (nagMinutes.present) {
      map['nag_minutes'] = Variable<int>(nagMinutes.value);
    }
    if (completable.present) {
      map['completable'] = Variable<bool>(completable.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (status.present) {
      map['status'] = Variable<String>($RemindersTable.$converterstatus.toSql(status.value));
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RemindersCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('rawInput: $rawInput, ')
          ..write('kind: $kind, ')
          ..write('context: $context, ')
          ..write('timingType: $timingType, ')
          ..write('startLocal: $startLocal, ')
          ..write('endLocal: $endLocal, ')
          ..write('tz: $tz, ')
          ..write('tzSetManually: $tzSetManually, ')
          ..write('rrule: $rrule, ')
          ..write('repeatMode: $repeatMode, ')
          ..write('alertPlan: $alertPlan, ')
          ..write('nagMinutes: $nagMinutes, ')
          ..write('completable: $completable, ')
          ..write('source: $source, ')
          ..write('templateId: $templateId, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $OccurrencesTable extends Occurrences with TableInfo<$OccurrencesTable, OccurrenceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OccurrencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderIdMeta = const VerificationMeta('reminderId');
  @override
  late final GeneratedColumn<String> reminderId = GeneratedColumn<String>(
    'reminder_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('REFERENCES reminders (id)'),
  );
  static const VerificationMeta _occurrenceKeyMeta = const VerificationMeta('occurrenceKey');
  @override
  late final GeneratedColumn<String> occurrenceKey = GeneratedColumn<String>(
    'occurrence_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<OccurrenceState, String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  ).withConverter<OccurrenceState>($OccurrencesTable.$converterstate);
  static const VerificationMeta _overrideStartMeta = const VerificationMeta('overrideStart');
  @override
  late final GeneratedColumn<String> overrideStart = GeneratedColumn<String>(
    'override_start',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideEndMeta = const VerificationMeta('overrideEnd');
  @override
  late final GeneratedColumn<String> overrideEnd = GeneratedColumn<String>(
    'override_end',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _overrideAlertPlanMeta = const VerificationMeta('overrideAlertPlan');
  @override
  late final GeneratedColumn<String> overrideAlertPlan = GeneratedColumn<String>(
    'override_alert_plan',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozedUntilMeta = const VerificationMeta('snoozedUntil');
  @override
  late final GeneratedColumn<DateTime> snoozedUntil = GeneratedColumn<DateTime>(
    'snoozed_until',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resolvedAtMeta = const VerificationMeta('resolvedAt');
  @override
  late final GeneratedColumn<DateTime> resolvedAt = GeneratedColumn<DateTime>(
    'resolved_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alertsSentMeta = const VerificationMeta('alertsSent');
  @override
  late final GeneratedColumn<String> alertsSent = GeneratedColumn<String>(
    'alerts_sent',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deviceId,
    deletedAt,
    reminderId,
    occurrenceKey,
    state,
    overrideStart,
    overrideEnd,
    overrideAlertPlan,
    snoozedUntil,
    resolvedAt,
    alertsSent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'occurrences';
  @override
  VerificationContext validateIntegrity(Insertable<OccurrenceRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta, deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('reminder_id')) {
      context.handle(_reminderIdMeta, reminderId.isAcceptableOrUnknown(data['reminder_id']!, _reminderIdMeta));
    } else if (isInserting) {
      context.missing(_reminderIdMeta);
    }
    if (data.containsKey('occurrence_key')) {
      context.handle(
        _occurrenceKeyMeta,
        occurrenceKey.isAcceptableOrUnknown(data['occurrence_key']!, _occurrenceKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_occurrenceKeyMeta);
    }
    if (data.containsKey('override_start')) {
      context.handle(
        _overrideStartMeta,
        overrideStart.isAcceptableOrUnknown(data['override_start']!, _overrideStartMeta),
      );
    }
    if (data.containsKey('override_end')) {
      context.handle(_overrideEndMeta, overrideEnd.isAcceptableOrUnknown(data['override_end']!, _overrideEndMeta));
    }
    if (data.containsKey('override_alert_plan')) {
      context.handle(
        _overrideAlertPlanMeta,
        overrideAlertPlan.isAcceptableOrUnknown(data['override_alert_plan']!, _overrideAlertPlanMeta),
      );
    }
    if (data.containsKey('snoozed_until')) {
      context.handle(_snoozedUntilMeta, snoozedUntil.isAcceptableOrUnknown(data['snoozed_until']!, _snoozedUntilMeta));
    }
    if (data.containsKey('resolved_at')) {
      context.handle(_resolvedAtMeta, resolvedAt.isAcceptableOrUnknown(data['resolved_at']!, _resolvedAtMeta));
    }
    if (data.containsKey('alerts_sent')) {
      context.handle(_alertsSentMeta, alertsSent.isAcceptableOrUnknown(data['alerts_sent']!, _alertsSentMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {reminderId, occurrenceKey},
  ];
  @override
  OccurrenceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return OccurrenceRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deviceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      reminderId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}reminder_id'])!,
      occurrenceKey: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}occurrence_key'])!,
      state: $OccurrencesTable.$converterstate.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}state'])!,
      ),
      overrideStart: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}override_start']),
      overrideEnd: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}override_end']),
      overrideAlertPlan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}override_alert_plan'],
      ),
      snoozedUntil: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}snoozed_until']),
      resolvedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}resolved_at']),
      alertsSent: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}alerts_sent'])!,
    );
  }

  @override
  $OccurrencesTable createAlias(String alias) {
    return $OccurrencesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<OccurrenceState, String, String> $converterstate = const EnumNameConverter<OccurrenceState>(
    OccurrenceState.values,
  );
}

class OccurrenceRow extends DataClass implements Insertable<OccurrenceRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceId;
  final DateTime? deletedAt;
  final String reminderId;
  final String occurrenceKey;
  final OccurrenceState state;
  final String? overrideStart;
  final String? overrideEnd;
  final String? overrideAlertPlan;
  final DateTime? snoozedUntil;
  final DateTime? resolvedAt;
  final String alertsSent;
  const OccurrenceRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.deletedAt,
    required this.reminderId,
    required this.occurrenceKey,
    required this.state,
    this.overrideStart,
    this.overrideEnd,
    this.overrideAlertPlan,
    this.snoozedUntil,
    this.resolvedAt,
    required this.alertsSent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['reminder_id'] = Variable<String>(reminderId);
    map['occurrence_key'] = Variable<String>(occurrenceKey);
    {
      map['state'] = Variable<String>($OccurrencesTable.$converterstate.toSql(state));
    }
    if (!nullToAbsent || overrideStart != null) {
      map['override_start'] = Variable<String>(overrideStart);
    }
    if (!nullToAbsent || overrideEnd != null) {
      map['override_end'] = Variable<String>(overrideEnd);
    }
    if (!nullToAbsent || overrideAlertPlan != null) {
      map['override_alert_plan'] = Variable<String>(overrideAlertPlan);
    }
    if (!nullToAbsent || snoozedUntil != null) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil);
    }
    if (!nullToAbsent || resolvedAt != null) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt);
    }
    map['alerts_sent'] = Variable<String>(alertsSent);
    return map;
  }

  OccurrencesCompanion toCompanion(bool nullToAbsent) {
    return OccurrencesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      reminderId: Value(reminderId),
      occurrenceKey: Value(occurrenceKey),
      state: Value(state),
      overrideStart: overrideStart == null && nullToAbsent ? const Value.absent() : Value(overrideStart),
      overrideEnd: overrideEnd == null && nullToAbsent ? const Value.absent() : Value(overrideEnd),
      overrideAlertPlan: overrideAlertPlan == null && nullToAbsent ? const Value.absent() : Value(overrideAlertPlan),
      snoozedUntil: snoozedUntil == null && nullToAbsent ? const Value.absent() : Value(snoozedUntil),
      resolvedAt: resolvedAt == null && nullToAbsent ? const Value.absent() : Value(resolvedAt),
      alertsSent: Value(alertsSent),
    );
  }

  factory OccurrenceRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return OccurrenceRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      reminderId: serializer.fromJson<String>(json['reminderId']),
      occurrenceKey: serializer.fromJson<String>(json['occurrenceKey']),
      state: $OccurrencesTable.$converterstate.fromJson(serializer.fromJson<String>(json['state'])),
      overrideStart: serializer.fromJson<String?>(json['overrideStart']),
      overrideEnd: serializer.fromJson<String?>(json['overrideEnd']),
      overrideAlertPlan: serializer.fromJson<String?>(json['overrideAlertPlan']),
      snoozedUntil: serializer.fromJson<DateTime?>(json['snoozedUntil']),
      resolvedAt: serializer.fromJson<DateTime?>(json['resolvedAt']),
      alertsSent: serializer.fromJson<String>(json['alertsSent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'reminderId': serializer.toJson<String>(reminderId),
      'occurrenceKey': serializer.toJson<String>(occurrenceKey),
      'state': serializer.toJson<String>($OccurrencesTable.$converterstate.toJson(state)),
      'overrideStart': serializer.toJson<String?>(overrideStart),
      'overrideEnd': serializer.toJson<String?>(overrideEnd),
      'overrideAlertPlan': serializer.toJson<String?>(overrideAlertPlan),
      'snoozedUntil': serializer.toJson<DateTime?>(snoozedUntil),
      'resolvedAt': serializer.toJson<DateTime?>(resolvedAt),
      'alertsSent': serializer.toJson<String>(alertsSent),
    };
  }

  OccurrenceRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? reminderId,
    String? occurrenceKey,
    OccurrenceState? state,
    Value<String?> overrideStart = const Value.absent(),
    Value<String?> overrideEnd = const Value.absent(),
    Value<String?> overrideAlertPlan = const Value.absent(),
    Value<DateTime?> snoozedUntil = const Value.absent(),
    Value<DateTime?> resolvedAt = const Value.absent(),
    String? alertsSent,
  }) => OccurrenceRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    reminderId: reminderId ?? this.reminderId,
    occurrenceKey: occurrenceKey ?? this.occurrenceKey,
    state: state ?? this.state,
    overrideStart: overrideStart.present ? overrideStart.value : this.overrideStart,
    overrideEnd: overrideEnd.present ? overrideEnd.value : this.overrideEnd,
    overrideAlertPlan: overrideAlertPlan.present ? overrideAlertPlan.value : this.overrideAlertPlan,
    snoozedUntil: snoozedUntil.present ? snoozedUntil.value : this.snoozedUntil,
    resolvedAt: resolvedAt.present ? resolvedAt.value : this.resolvedAt,
    alertsSent: alertsSent ?? this.alertsSent,
  );
  OccurrenceRow copyWithCompanion(OccurrencesCompanion data) {
    return OccurrenceRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      reminderId: data.reminderId.present ? data.reminderId.value : this.reminderId,
      occurrenceKey: data.occurrenceKey.present ? data.occurrenceKey.value : this.occurrenceKey,
      state: data.state.present ? data.state.value : this.state,
      overrideStart: data.overrideStart.present ? data.overrideStart.value : this.overrideStart,
      overrideEnd: data.overrideEnd.present ? data.overrideEnd.value : this.overrideEnd,
      overrideAlertPlan: data.overrideAlertPlan.present ? data.overrideAlertPlan.value : this.overrideAlertPlan,
      snoozedUntil: data.snoozedUntil.present ? data.snoozedUntil.value : this.snoozedUntil,
      resolvedAt: data.resolvedAt.present ? data.resolvedAt.value : this.resolvedAt,
      alertsSent: data.alertsSent.present ? data.alertsSent.value : this.alertsSent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('OccurrenceRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('reminderId: $reminderId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('state: $state, ')
          ..write('overrideStart: $overrideStart, ')
          ..write('overrideEnd: $overrideEnd, ')
          ..write('overrideAlertPlan: $overrideAlertPlan, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('alertsSent: $alertsSent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deviceId,
    deletedAt,
    reminderId,
    occurrenceKey,
    state,
    overrideStart,
    overrideEnd,
    overrideAlertPlan,
    snoozedUntil,
    resolvedAt,
    alertsSent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is OccurrenceRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deletedAt == this.deletedAt &&
          other.reminderId == this.reminderId &&
          other.occurrenceKey == this.occurrenceKey &&
          other.state == this.state &&
          other.overrideStart == this.overrideStart &&
          other.overrideEnd == this.overrideEnd &&
          other.overrideAlertPlan == this.overrideAlertPlan &&
          other.snoozedUntil == this.snoozedUntil &&
          other.resolvedAt == this.resolvedAt &&
          other.alertsSent == this.alertsSent);
}

class OccurrencesCompanion extends UpdateCompanion<OccurrenceRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<DateTime?> deletedAt;
  final Value<String> reminderId;
  final Value<String> occurrenceKey;
  final Value<OccurrenceState> state;
  final Value<String?> overrideStart;
  final Value<String?> overrideEnd;
  final Value<String?> overrideAlertPlan;
  final Value<DateTime?> snoozedUntil;
  final Value<DateTime?> resolvedAt;
  final Value<String> alertsSent;
  final Value<int> rowid;
  const OccurrencesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.reminderId = const Value.absent(),
    this.occurrenceKey = const Value.absent(),
    this.state = const Value.absent(),
    this.overrideStart = const Value.absent(),
    this.overrideEnd = const Value.absent(),
    this.overrideAlertPlan = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.alertsSent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  OccurrencesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String deviceId,
    this.deletedAt = const Value.absent(),
    required String reminderId,
    required String occurrenceKey,
    required OccurrenceState state,
    this.overrideStart = const Value.absent(),
    this.overrideEnd = const Value.absent(),
    this.overrideAlertPlan = const Value.absent(),
    this.snoozedUntil = const Value.absent(),
    this.resolvedAt = const Value.absent(),
    this.alertsSent = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       reminderId = Value(reminderId),
       occurrenceKey = Value(occurrenceKey),
       state = Value(state);
  static Insertable<OccurrenceRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? deletedAt,
    Expression<String>? reminderId,
    Expression<String>? occurrenceKey,
    Expression<String>? state,
    Expression<String>? overrideStart,
    Expression<String>? overrideEnd,
    Expression<String>? overrideAlertPlan,
    Expression<DateTime>? snoozedUntil,
    Expression<DateTime>? resolvedAt,
    Expression<String>? alertsSent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (reminderId != null) 'reminder_id': reminderId,
      if (occurrenceKey != null) 'occurrence_key': occurrenceKey,
      if (state != null) 'state': state,
      if (overrideStart != null) 'override_start': overrideStart,
      if (overrideEnd != null) 'override_end': overrideEnd,
      if (overrideAlertPlan != null) 'override_alert_plan': overrideAlertPlan,
      if (snoozedUntil != null) 'snoozed_until': snoozedUntil,
      if (resolvedAt != null) 'resolved_at': resolvedAt,
      if (alertsSent != null) 'alerts_sent': alertsSent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  OccurrencesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<DateTime?>? deletedAt,
    Value<String>? reminderId,
    Value<String>? occurrenceKey,
    Value<OccurrenceState>? state,
    Value<String?>? overrideStart,
    Value<String?>? overrideEnd,
    Value<String?>? overrideAlertPlan,
    Value<DateTime?>? snoozedUntil,
    Value<DateTime?>? resolvedAt,
    Value<String>? alertsSent,
    Value<int>? rowid,
  }) {
    return OccurrencesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deletedAt: deletedAt ?? this.deletedAt,
      reminderId: reminderId ?? this.reminderId,
      occurrenceKey: occurrenceKey ?? this.occurrenceKey,
      state: state ?? this.state,
      overrideStart: overrideStart ?? this.overrideStart,
      overrideEnd: overrideEnd ?? this.overrideEnd,
      overrideAlertPlan: overrideAlertPlan ?? this.overrideAlertPlan,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      alertsSent: alertsSent ?? this.alertsSent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (reminderId.present) {
      map['reminder_id'] = Variable<String>(reminderId.value);
    }
    if (occurrenceKey.present) {
      map['occurrence_key'] = Variable<String>(occurrenceKey.value);
    }
    if (state.present) {
      map['state'] = Variable<String>($OccurrencesTable.$converterstate.toSql(state.value));
    }
    if (overrideStart.present) {
      map['override_start'] = Variable<String>(overrideStart.value);
    }
    if (overrideEnd.present) {
      map['override_end'] = Variable<String>(overrideEnd.value);
    }
    if (overrideAlertPlan.present) {
      map['override_alert_plan'] = Variable<String>(overrideAlertPlan.value);
    }
    if (snoozedUntil.present) {
      map['snoozed_until'] = Variable<DateTime>(snoozedUntil.value);
    }
    if (resolvedAt.present) {
      map['resolved_at'] = Variable<DateTime>(resolvedAt.value);
    }
    if (alertsSent.present) {
      map['alerts_sent'] = Variable<String>(alertsSent.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('OccurrencesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('reminderId: $reminderId, ')
          ..write('occurrenceKey: $occurrenceKey, ')
          ..write('state: $state, ')
          ..write('overrideStart: $overrideStart, ')
          ..write('overrideEnd: $overrideEnd, ')
          ..write('overrideAlertPlan: $overrideAlertPlan, ')
          ..write('snoozedUntil: $snoozedUntil, ')
          ..write('resolvedAt: $resolvedAt, ')
          ..write('alertsSent: $alertsSent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarOverlaysTable extends CalendarOverlays with TableInfo<$CalendarOverlaysTable, CalendarOverlayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarOverlaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta('deviceId');
  @override
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta('deletedAt');
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _calendarIdMeta = const VerificationMeta('calendarId');
  @override
  late final GeneratedColumn<String> calendarId = GeneratedColumn<String>(
    'calendar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventIdMeta = const VerificationMeta('eventId');
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seriesIdMeta = const VerificationMeta('seriesId');
  @override
  late final GeneratedColumn<String> seriesId = GeneratedColumn<String>(
    'series_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _alertPlanMeta = const VerificationMeta('alertPlan');
  @override
  late final GeneratedColumn<String> alertPlan = GeneratedColumn<String>(
    'alert_plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<Kind?, String> kindOverride = GeneratedColumn<String>(
    'kind_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<Kind?>($CalendarOverlaysTable.$converterkindOverriden);
  @override
  late final GeneratedColumnWithTypeConverter<ReminderContext?, String> contextOverride = GeneratedColumn<String>(
    'context_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  ).withConverter<ReminderContext?>($CalendarOverlaysTable.$convertercontextOverriden);
  static const VerificationMeta _scopeMeta = const VerificationMeta('scope');
  @override
  late final GeneratedColumn<String> scope = GeneratedColumn<String>(
    'scope',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _orphanedAtMeta = const VerificationMeta('orphanedAt');
  @override
  late final GeneratedColumn<DateTime> orphanedAt = GeneratedColumn<DateTime>(
    'orphaned_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    deviceId,
    deletedAt,
    calendarId,
    eventId,
    seriesId,
    alertPlan,
    kindOverride,
    contextOverride,
    scope,
    orphanedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_overlays';
  @override
  VerificationContext validateIntegrity(Insertable<CalendarOverlayRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta, createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(_deviceIdMeta, deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta));
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(_deletedAtMeta, deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta));
    }
    if (data.containsKey('calendar_id')) {
      context.handle(_calendarIdMeta, calendarId.isAcceptableOrUnknown(data['calendar_id']!, _calendarIdMeta));
    } else if (isInserting) {
      context.missing(_calendarIdMeta);
    }
    if (data.containsKey('event_id')) {
      context.handle(_eventIdMeta, eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta));
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('series_id')) {
      context.handle(_seriesIdMeta, seriesId.isAcceptableOrUnknown(data['series_id']!, _seriesIdMeta));
    }
    if (data.containsKey('alert_plan')) {
      context.handle(_alertPlanMeta, alertPlan.isAcceptableOrUnknown(data['alert_plan']!, _alertPlanMeta));
    } else if (isInserting) {
      context.missing(_alertPlanMeta);
    }
    if (data.containsKey('scope')) {
      context.handle(_scopeMeta, scope.isAcceptableOrUnknown(data['scope']!, _scopeMeta));
    } else if (isInserting) {
      context.missing(_scopeMeta);
    }
    if (data.containsKey('orphaned_at')) {
      context.handle(_orphanedAtMeta, orphanedAt.isAcceptableOrUnknown(data['orphaned_at']!, _orphanedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarOverlayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarOverlayRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      createdAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
      deviceId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}device_id'])!,
      deletedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}deleted_at']),
      calendarId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}calendar_id'])!,
      eventId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}event_id'])!,
      seriesId: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}series_id']),
      alertPlan: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}alert_plan'])!,
      kindOverride: $CalendarOverlaysTable.$converterkindOverriden.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}kind_override']),
      ),
      contextOverride: $CalendarOverlaysTable.$convertercontextOverriden.fromSql(
        attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}context_override']),
      ),
      scope: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}scope'])!,
      orphanedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}orphaned_at']),
    );
  }

  @override
  $CalendarOverlaysTable createAlias(String alias) {
    return $CalendarOverlaysTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<Kind, String, String> $converterkindOverride = const EnumNameConverter<Kind>(Kind.values);
  static JsonTypeConverter2<Kind?, String?, String?> $converterkindOverriden = JsonTypeConverter2.asNullable(
    $converterkindOverride,
  );
  static JsonTypeConverter2<ReminderContext, String, String> $convertercontextOverride =
      const EnumNameConverter<ReminderContext>(ReminderContext.values);
  static JsonTypeConverter2<ReminderContext?, String?, String?> $convertercontextOverriden =
      JsonTypeConverter2.asNullable($convertercontextOverride);
}

class CalendarOverlayRow extends DataClass implements Insertable<CalendarOverlayRow> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String deviceId;
  final DateTime? deletedAt;
  final String calendarId;
  final String eventId;
  final String? seriesId;
  final String alertPlan;
  final Kind? kindOverride;
  final ReminderContext? contextOverride;
  final String scope;
  final DateTime? orphanedAt;
  const CalendarOverlayRow({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.deviceId,
    this.deletedAt,
    required this.calendarId,
    required this.eventId,
    this.seriesId,
    required this.alertPlan,
    this.kindOverride,
    this.contextOverride,
    required this.scope,
    this.orphanedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['device_id'] = Variable<String>(deviceId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['calendar_id'] = Variable<String>(calendarId);
    map['event_id'] = Variable<String>(eventId);
    if (!nullToAbsent || seriesId != null) {
      map['series_id'] = Variable<String>(seriesId);
    }
    map['alert_plan'] = Variable<String>(alertPlan);
    if (!nullToAbsent || kindOverride != null) {
      map['kind_override'] = Variable<String>($CalendarOverlaysTable.$converterkindOverriden.toSql(kindOverride));
    }
    if (!nullToAbsent || contextOverride != null) {
      map['context_override'] = Variable<String>(
        $CalendarOverlaysTable.$convertercontextOverriden.toSql(contextOverride),
      );
    }
    map['scope'] = Variable<String>(scope);
    if (!nullToAbsent || orphanedAt != null) {
      map['orphaned_at'] = Variable<DateTime>(orphanedAt);
    }
    return map;
  }

  CalendarOverlaysCompanion toCompanion(bool nullToAbsent) {
    return CalendarOverlaysCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deviceId: Value(deviceId),
      deletedAt: deletedAt == null && nullToAbsent ? const Value.absent() : Value(deletedAt),
      calendarId: Value(calendarId),
      eventId: Value(eventId),
      seriesId: seriesId == null && nullToAbsent ? const Value.absent() : Value(seriesId),
      alertPlan: Value(alertPlan),
      kindOverride: kindOverride == null && nullToAbsent ? const Value.absent() : Value(kindOverride),
      contextOverride: contextOverride == null && nullToAbsent ? const Value.absent() : Value(contextOverride),
      scope: Value(scope),
      orphanedAt: orphanedAt == null && nullToAbsent ? const Value.absent() : Value(orphanedAt),
    );
  }

  factory CalendarOverlayRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarOverlayRow(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deviceId: serializer.fromJson<String>(json['deviceId']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      calendarId: serializer.fromJson<String>(json['calendarId']),
      eventId: serializer.fromJson<String>(json['eventId']),
      seriesId: serializer.fromJson<String?>(json['seriesId']),
      alertPlan: serializer.fromJson<String>(json['alertPlan']),
      kindOverride: $CalendarOverlaysTable.$converterkindOverriden.fromJson(
        serializer.fromJson<String?>(json['kindOverride']),
      ),
      contextOverride: $CalendarOverlaysTable.$convertercontextOverriden.fromJson(
        serializer.fromJson<String?>(json['contextOverride']),
      ),
      scope: serializer.fromJson<String>(json['scope']),
      orphanedAt: serializer.fromJson<DateTime?>(json['orphanedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deviceId': serializer.toJson<String>(deviceId),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'calendarId': serializer.toJson<String>(calendarId),
      'eventId': serializer.toJson<String>(eventId),
      'seriesId': serializer.toJson<String?>(seriesId),
      'alertPlan': serializer.toJson<String>(alertPlan),
      'kindOverride': serializer.toJson<String?>($CalendarOverlaysTable.$converterkindOverriden.toJson(kindOverride)),
      'contextOverride': serializer.toJson<String?>(
        $CalendarOverlaysTable.$convertercontextOverriden.toJson(contextOverride),
      ),
      'scope': serializer.toJson<String>(scope),
      'orphanedAt': serializer.toJson<DateTime?>(orphanedAt),
    };
  }

  CalendarOverlayRow copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? deviceId,
    Value<DateTime?> deletedAt = const Value.absent(),
    String? calendarId,
    String? eventId,
    Value<String?> seriesId = const Value.absent(),
    String? alertPlan,
    Value<Kind?> kindOverride = const Value.absent(),
    Value<ReminderContext?> contextOverride = const Value.absent(),
    String? scope,
    Value<DateTime?> orphanedAt = const Value.absent(),
  }) => CalendarOverlayRow(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deviceId: deviceId ?? this.deviceId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    calendarId: calendarId ?? this.calendarId,
    eventId: eventId ?? this.eventId,
    seriesId: seriesId.present ? seriesId.value : this.seriesId,
    alertPlan: alertPlan ?? this.alertPlan,
    kindOverride: kindOverride.present ? kindOverride.value : this.kindOverride,
    contextOverride: contextOverride.present ? contextOverride.value : this.contextOverride,
    scope: scope ?? this.scope,
    orphanedAt: orphanedAt.present ? orphanedAt.value : this.orphanedAt,
  );
  CalendarOverlayRow copyWithCompanion(CalendarOverlaysCompanion data) {
    return CalendarOverlayRow(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      calendarId: data.calendarId.present ? data.calendarId.value : this.calendarId,
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      seriesId: data.seriesId.present ? data.seriesId.value : this.seriesId,
      alertPlan: data.alertPlan.present ? data.alertPlan.value : this.alertPlan,
      kindOverride: data.kindOverride.present ? data.kindOverride.value : this.kindOverride,
      contextOverride: data.contextOverride.present ? data.contextOverride.value : this.contextOverride,
      scope: data.scope.present ? data.scope.value : this.scope,
      orphanedAt: data.orphanedAt.present ? data.orphanedAt.value : this.orphanedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarOverlayRow(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('calendarId: $calendarId, ')
          ..write('eventId: $eventId, ')
          ..write('seriesId: $seriesId, ')
          ..write('alertPlan: $alertPlan, ')
          ..write('kindOverride: $kindOverride, ')
          ..write('contextOverride: $contextOverride, ')
          ..write('scope: $scope, ')
          ..write('orphanedAt: $orphanedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    deviceId,
    deletedAt,
    calendarId,
    eventId,
    seriesId,
    alertPlan,
    kindOverride,
    contextOverride,
    scope,
    orphanedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarOverlayRow &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deviceId == this.deviceId &&
          other.deletedAt == this.deletedAt &&
          other.calendarId == this.calendarId &&
          other.eventId == this.eventId &&
          other.seriesId == this.seriesId &&
          other.alertPlan == this.alertPlan &&
          other.kindOverride == this.kindOverride &&
          other.contextOverride == this.contextOverride &&
          other.scope == this.scope &&
          other.orphanedAt == this.orphanedAt);
}

class CalendarOverlaysCompanion extends UpdateCompanion<CalendarOverlayRow> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> deviceId;
  final Value<DateTime?> deletedAt;
  final Value<String> calendarId;
  final Value<String> eventId;
  final Value<String?> seriesId;
  final Value<String> alertPlan;
  final Value<Kind?> kindOverride;
  final Value<ReminderContext?> contextOverride;
  final Value<String> scope;
  final Value<DateTime?> orphanedAt;
  final Value<int> rowid;
  const CalendarOverlaysCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.calendarId = const Value.absent(),
    this.eventId = const Value.absent(),
    this.seriesId = const Value.absent(),
    this.alertPlan = const Value.absent(),
    this.kindOverride = const Value.absent(),
    this.contextOverride = const Value.absent(),
    this.scope = const Value.absent(),
    this.orphanedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarOverlaysCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String deviceId,
    this.deletedAt = const Value.absent(),
    required String calendarId,
    required String eventId,
    this.seriesId = const Value.absent(),
    required String alertPlan,
    this.kindOverride = const Value.absent(),
    this.contextOverride = const Value.absent(),
    required String scope,
    this.orphanedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       deviceId = Value(deviceId),
       calendarId = Value(calendarId),
       eventId = Value(eventId),
       alertPlan = Value(alertPlan),
       scope = Value(scope);
  static Insertable<CalendarOverlayRow> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? deviceId,
    Expression<DateTime>? deletedAt,
    Expression<String>? calendarId,
    Expression<String>? eventId,
    Expression<String>? seriesId,
    Expression<String>? alertPlan,
    Expression<String>? kindOverride,
    Expression<String>? contextOverride,
    Expression<String>? scope,
    Expression<DateTime>? orphanedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deviceId != null) 'device_id': deviceId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (calendarId != null) 'calendar_id': calendarId,
      if (eventId != null) 'event_id': eventId,
      if (seriesId != null) 'series_id': seriesId,
      if (alertPlan != null) 'alert_plan': alertPlan,
      if (kindOverride != null) 'kind_override': kindOverride,
      if (contextOverride != null) 'context_override': contextOverride,
      if (scope != null) 'scope': scope,
      if (orphanedAt != null) 'orphaned_at': orphanedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarOverlaysCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? deviceId,
    Value<DateTime?>? deletedAt,
    Value<String>? calendarId,
    Value<String>? eventId,
    Value<String?>? seriesId,
    Value<String>? alertPlan,
    Value<Kind?>? kindOverride,
    Value<ReminderContext?>? contextOverride,
    Value<String>? scope,
    Value<DateTime?>? orphanedAt,
    Value<int>? rowid,
  }) {
    return CalendarOverlaysCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deviceId: deviceId ?? this.deviceId,
      deletedAt: deletedAt ?? this.deletedAt,
      calendarId: calendarId ?? this.calendarId,
      eventId: eventId ?? this.eventId,
      seriesId: seriesId ?? this.seriesId,
      alertPlan: alertPlan ?? this.alertPlan,
      kindOverride: kindOverride ?? this.kindOverride,
      contextOverride: contextOverride ?? this.contextOverride,
      scope: scope ?? this.scope,
      orphanedAt: orphanedAt ?? this.orphanedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (calendarId.present) {
      map['calendar_id'] = Variable<String>(calendarId.value);
    }
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (seriesId.present) {
      map['series_id'] = Variable<String>(seriesId.value);
    }
    if (alertPlan.present) {
      map['alert_plan'] = Variable<String>(alertPlan.value);
    }
    if (kindOverride.present) {
      map['kind_override'] = Variable<String>($CalendarOverlaysTable.$converterkindOverriden.toSql(kindOverride.value));
    }
    if (contextOverride.present) {
      map['context_override'] = Variable<String>(
        $CalendarOverlaysTable.$convertercontextOverriden.toSql(contextOverride.value),
      );
    }
    if (scope.present) {
      map['scope'] = Variable<String>(scope.value);
    }
    if (orphanedAt.present) {
      map['orphaned_at'] = Variable<DateTime>(orphanedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarOverlaysCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deviceId: $deviceId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('calendarId: $calendarId, ')
          ..write('eventId: $eventId, ')
          ..write('seriesId: $seriesId, ')
          ..write('alertPlan: $alertPlan, ')
          ..write('kindOverride: $kindOverride, ')
          ..write('contextOverride: $contextOverride, ')
          ..write('scope: $scope, ')
          ..write('orphanedAt: $orphanedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrefsTable extends Prefs with TableInfo<$PrefsTable, PrefRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrefsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prefs';
  @override
  VerificationContext validateIntegrity(Insertable<PrefRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta, updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PrefRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrefRow(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}value'])!,
      updatedAt: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $PrefsTable createAlias(String alias) {
    return $PrefsTable(attachedDatabase, alias);
  }
}

class PrefRow extends DataClass implements Insertable<PrefRow> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const PrefRow({required this.key, required this.value, required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  PrefsCompanion toCompanion(bool nullToAbsent) {
    return PrefsCompanion(key: Value(key), value: Value(value), updatedAt: Value(updatedAt));
  }

  factory PrefRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrefRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  PrefRow copyWith({String? key, String? value, DateTime? updatedAt}) =>
      PrefRow(key: key ?? this.key, value: value ?? this.value, updatedAt: updatedAt ?? this.updatedAt);
  PrefRow copyWithCompanion(PrefsCompanion data) {
    return PrefRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrefRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrefRow && other.key == this.key && other.value == this.value && other.updatedAt == this.updatedAt);
}

class PrefsCompanion extends UpdateCompanion<PrefRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const PrefsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrefsCompanion.insert({
    required String key,
    required String value,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       updatedAt = Value(updatedAt);
  static Insertable<PrefRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrefsCompanion copyWith({Value<String>? key, Value<String>? value, Value<DateTime>? updatedAt, Value<int>? rowid}) {
    return PrefsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrefsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MetricsQueueTable extends MetricsQueue with TableInfo<$MetricsQueueTable, MetricRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MetricsQueueTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _propsMeta = const VerificationMeta('props');
  @override
  late final GeneratedColumn<String> props = GeneratedColumn<String>(
    'props',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _atMeta = const VerificationMeta('at');
  @override
  late final GeneratedColumn<DateTime> at = GeneratedColumn<DateTime>(
    'at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, props, at];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'metrics_queue';
  @override
  VerificationContext validateIntegrity(Insertable<MetricRow> instance, {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(_nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('props')) {
      context.handle(_propsMeta, props.isAcceptableOrUnknown(data['props']!, _propsMeta));
    } else if (isInserting) {
      context.missing(_propsMeta);
    }
    if (data.containsKey('at')) {
      context.handle(_atMeta, at.isAcceptableOrUnknown(data['at']!, _atMeta));
    } else if (isInserting) {
      context.missing(_atMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MetricRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MetricRow(
      id: attachedDatabase.typeMapping.read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      props: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}props'])!,
      at: attachedDatabase.typeMapping.read(DriftSqlType.dateTime, data['${effectivePrefix}at'])!,
    );
  }

  @override
  $MetricsQueueTable createAlias(String alias) {
    return $MetricsQueueTable(attachedDatabase, alias);
  }
}

class MetricRow extends DataClass implements Insertable<MetricRow> {
  final int id;
  final String name;
  final String props;
  final DateTime at;
  const MetricRow({required this.id, required this.name, required this.props, required this.at});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['props'] = Variable<String>(props);
    map['at'] = Variable<DateTime>(at);
    return map;
  }

  MetricsQueueCompanion toCompanion(bool nullToAbsent) {
    return MetricsQueueCompanion(id: Value(id), name: Value(name), props: Value(props), at: Value(at));
  }

  factory MetricRow.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MetricRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      props: serializer.fromJson<String>(json['props']),
      at: serializer.fromJson<DateTime>(json['at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'props': serializer.toJson<String>(props),
      'at': serializer.toJson<DateTime>(at),
    };
  }

  MetricRow copyWith({int? id, String? name, String? props, DateTime? at}) =>
      MetricRow(id: id ?? this.id, name: name ?? this.name, props: props ?? this.props, at: at ?? this.at);
  MetricRow copyWithCompanion(MetricsQueueCompanion data) {
    return MetricRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      props: data.props.present ? data.props.value : this.props,
      at: data.at.present ? data.at.value : this.at,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MetricRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('props: $props, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, props, at);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MetricRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.props == this.props &&
          other.at == this.at);
}

class MetricsQueueCompanion extends UpdateCompanion<MetricRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> props;
  final Value<DateTime> at;
  const MetricsQueueCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.props = const Value.absent(),
    this.at = const Value.absent(),
  });
  MetricsQueueCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String props,
    required DateTime at,
  }) : name = Value(name),
       props = Value(props),
       at = Value(at);
  static Insertable<MetricRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? props,
    Expression<DateTime>? at,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (props != null) 'props': props,
      if (at != null) 'at': at,
    });
  }

  MetricsQueueCompanion copyWith({Value<int>? id, Value<String>? name, Value<String>? props, Value<DateTime>? at}) {
    return MetricsQueueCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      props: props ?? this.props,
      at: at ?? this.at,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (props.present) {
      map['props'] = Variable<String>(props.value);
    }
    if (at.present) {
      map['at'] = Variable<DateTime>(at.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MetricsQueueCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('props: $props, ')
          ..write('at: $at')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $RemindersTable reminders = $RemindersTable(this);
  late final $OccurrencesTable occurrences = $OccurrencesTable(this);
  late final $CalendarOverlaysTable calendarOverlays = $CalendarOverlaysTable(this);
  late final $PrefsTable prefs = $PrefsTable(this);
  late final $MetricsQueueTable metricsQueue = $MetricsQueueTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables => allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [reminders, occurrences, calendarOverlays, prefs, metricsQueue];
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$RemindersTableCreateCompanionBuilder = RemindersCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String deviceId,
  Value<DateTime?> deletedAt,
  required String title,
  Value<String?> notes,
  Value<String?> rawInput,
  required Kind kind,
  required ReminderContext context,
  required TimingType timingType,
  required String startLocal,
  Value<String?> endLocal,
  Value<String?> tz,
  Value<bool> tzSetManually,
  Value<String?> rrule,
  required RecurrenceMode repeatMode,
  required String alertPlan,
  Value<int?> nagMinutes,
  required bool completable,
  required String source,
  Value<String?> templateId,
  required ReminderStatus status,
  Value<int> rowid,
});
typedef $$RemindersTableUpdateCompanionBuilder = RemindersCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> deviceId,
  Value<DateTime?> deletedAt,
  Value<String> title,
  Value<String?> notes,
  Value<String?> rawInput,
  Value<Kind> kind,
  Value<ReminderContext> context,
  Value<TimingType> timingType,
  Value<String> startLocal,
  Value<String?> endLocal,
  Value<String?> tz,
  Value<bool> tzSetManually,
  Value<String?> rrule,
  Value<RecurrenceMode> repeatMode,
  Value<String> alertPlan,
  Value<int?> nagMinutes,
  Value<bool> completable,
  Value<String> source,
  Value<String?> templateId,
  Value<ReminderStatus> status,
  Value<int> rowid,
});

final class $$RemindersTableReferences extends BaseReferences<_$AppDatabase, $RemindersTable, ReminderRow> {
  $$RemindersTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$OccurrencesTable, List<OccurrenceRow>> _occurrencesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.occurrences, aliasName: 'reminders__id__occurrences__reminder_id');

  $$OccurrencesTableProcessedTableManager get occurrencesRefs {
    final manager = $$OccurrencesTableTableManager(
      $_db,
      $_db.occurrences,
    ).filter((f) => f.reminderId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_occurrencesRefsTable($_db));
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$RemindersTableFilterComposer extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rawInput =>
      $composableBuilder(column: $table.rawInput, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Kind, Kind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ReminderContext, ReminderContext, String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<TimingType, TimingType, String> get timingType =>
      $composableBuilder(column: $table.timingType, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get startLocal =>
      $composableBuilder(column: $table.startLocal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get endLocal =>
      $composableBuilder(column: $table.endLocal, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get tz => $composableBuilder(column: $table.tz, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get tzSetManually =>
      $composableBuilder(column: $table.tzSetManually, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<RecurrenceMode, RecurrenceMode, String> get repeatMode =>
      $composableBuilder(column: $table.repeatMode, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get alertPlan =>
      $composableBuilder(column: $table.alertPlan, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get nagMinutes =>
      $composableBuilder(column: $table.nagMinutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get completable =>
      $composableBuilder(column: $table.completable, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get templateId =>
      $composableBuilder(column: $table.templateId, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<ReminderStatus, ReminderStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnWithTypeConverterFilters(column));

  Expression<bool> occurrencesRefs(Expression<bool> Function($$OccurrencesTableFilterComposer f) f) {
    final $$OccurrencesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.reminderId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$OccurrencesTableFilterComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemindersTableOrderingComposer extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rawInput =>
      $composableBuilder(column: $table.rawInput, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get timingType =>
      $composableBuilder(column: $table.timingType, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get startLocal =>
      $composableBuilder(column: $table.startLocal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get endLocal =>
      $composableBuilder(column: $table.endLocal, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get tz => $composableBuilder(column: $table.tz, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get tzSetManually =>
      $composableBuilder(column: $table.tzSetManually, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rrule =>
      $composableBuilder(column: $table.rrule, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get repeatMode =>
      $composableBuilder(column: $table.repeatMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alertPlan =>
      $composableBuilder(column: $table.alertPlan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get nagMinutes =>
      $composableBuilder(column: $table.nagMinutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get completable =>
      $composableBuilder(column: $table.completable, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get templateId =>
      $composableBuilder(column: $table.templateId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$RemindersTableAnnotationComposer extends Composer<_$AppDatabase, $RemindersTable> {
  $$RemindersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId => $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get title => $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes => $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get rawInput => $composableBuilder(column: $table.rawInput, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Kind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderContext, String> get context =>
      $composableBuilder(column: $table.context, builder: (column) => column);

  GeneratedColumnWithTypeConverter<TimingType, String> get timingType =>
      $composableBuilder(column: $table.timingType, builder: (column) => column);

  GeneratedColumn<String> get startLocal => $composableBuilder(column: $table.startLocal, builder: (column) => column);

  GeneratedColumn<String> get endLocal => $composableBuilder(column: $table.endLocal, builder: (column) => column);

  GeneratedColumn<String> get tz => $composableBuilder(column: $table.tz, builder: (column) => column);

  GeneratedColumn<bool> get tzSetManually =>
      $composableBuilder(column: $table.tzSetManually, builder: (column) => column);

  GeneratedColumn<String> get rrule => $composableBuilder(column: $table.rrule, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RecurrenceMode, String> get repeatMode =>
      $composableBuilder(column: $table.repeatMode, builder: (column) => column);

  GeneratedColumn<String> get alertPlan => $composableBuilder(column: $table.alertPlan, builder: (column) => column);

  GeneratedColumn<int> get nagMinutes => $composableBuilder(column: $table.nagMinutes, builder: (column) => column);

  GeneratedColumn<bool> get completable => $composableBuilder(column: $table.completable, builder: (column) => column);

  GeneratedColumn<String> get source => $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(column: $table.templateId, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  Expression<T> occurrencesRefs<T extends Object>(Expression<T> Function($$OccurrencesTableAnnotationComposer a) f) {
    final $$OccurrencesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.occurrences,
      getReferencedColumn: (t) => t.reminderId,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$OccurrencesTableAnnotationComposer(
            $db: $db,
            $table: $db.occurrences,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$RemindersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RemindersTable,
          ReminderRow,
          $$RemindersTableFilterComposer,
          $$RemindersTableOrderingComposer,
          $$RemindersTableAnnotationComposer,
          $$RemindersTableCreateCompanionBuilder,
          $$RemindersTableUpdateCompanionBuilder,
          (ReminderRow, $$RemindersTableReferences),
          ReminderRow,
          PrefetchHooks Function({bool occurrencesRefs})
        > {
  $$RemindersTableTableManager(_$AppDatabase db, $RemindersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$RemindersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$RemindersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$RemindersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> rawInput = const Value.absent(),
                Value<Kind> kind = const Value.absent(),
                Value<ReminderContext> context = const Value.absent(),
                Value<TimingType> timingType = const Value.absent(),
                Value<String> startLocal = const Value.absent(),
                Value<String?> endLocal = const Value.absent(),
                Value<String?> tz = const Value.absent(),
                Value<bool> tzSetManually = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                Value<RecurrenceMode> repeatMode = const Value.absent(),
                Value<String> alertPlan = const Value.absent(),
                Value<int?> nagMinutes = const Value.absent(),
                Value<bool> completable = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<ReminderStatus> status = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deletedAt: deletedAt,
                title: title,
                notes: notes,
                rawInput: rawInput,
                kind: kind,
                context: context,
                timingType: timingType,
                startLocal: startLocal,
                endLocal: endLocal,
                tz: tz,
                tzSetManually: tzSetManually,
                rrule: rrule,
                repeatMode: repeatMode,
                alertPlan: alertPlan,
                nagMinutes: nagMinutes,
                completable: completable,
                source: source,
                templateId: templateId,
                status: status,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String deviceId,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<String?> rawInput = const Value.absent(),
                required Kind kind,
                required ReminderContext context,
                required TimingType timingType,
                required String startLocal,
                Value<String?> endLocal = const Value.absent(),
                Value<String?> tz = const Value.absent(),
                Value<bool> tzSetManually = const Value.absent(),
                Value<String?> rrule = const Value.absent(),
                required RecurrenceMode repeatMode,
                required String alertPlan,
                Value<int?> nagMinutes = const Value.absent(),
                required bool completable,
                required String source,
                Value<String?> templateId = const Value.absent(),
                required ReminderStatus status,
                Value<int> rowid = const Value.absent(),
              }) => RemindersCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deletedAt: deletedAt,
                title: title,
                notes: notes,
                rawInput: rawInput,
                kind: kind,
                context: context,
                timingType: timingType,
                startLocal: startLocal,
                endLocal: endLocal,
                tz: tz,
                tzSetManually: tzSetManually,
                rrule: rrule,
                repeatMode: repeatMode,
                alertPlan: alertPlan,
                nagMinutes: nagMinutes,
                completable: completable,
                source: source,
                templateId: templateId,
                status: status,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable<$RemindersTable, ReminderRow>(table), $$RemindersTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({occurrencesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (occurrencesRefs) db.occurrences],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (occurrencesRefs)
                    await $_getPrefetchedData<ReminderRow, $RemindersTable, OccurrenceRow>(
                      currentTable: table,
                      referencedTable: $$RemindersTableReferences._occurrencesRefsTable(db),
                      managerFromTypedResult: (p0) => $$RemindersTableReferences(db, table, p0).occurrencesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.reminderId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$RemindersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RemindersTable,
      ReminderRow,
      $$RemindersTableFilterComposer,
      $$RemindersTableOrderingComposer,
      $$RemindersTableAnnotationComposer,
      $$RemindersTableCreateCompanionBuilder,
      $$RemindersTableUpdateCompanionBuilder,
      (ReminderRow, $$RemindersTableReferences),
      ReminderRow,
      PrefetchHooks Function({bool occurrencesRefs})
    >;
typedef $$OccurrencesTableCreateCompanionBuilder = OccurrencesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String deviceId,
  Value<DateTime?> deletedAt,
  required String reminderId,
  required String occurrenceKey,
  required OccurrenceState state,
  Value<String?> overrideStart,
  Value<String?> overrideEnd,
  Value<String?> overrideAlertPlan,
  Value<DateTime?> snoozedUntil,
  Value<DateTime?> resolvedAt,
  Value<String> alertsSent,
  Value<int> rowid,
});
typedef $$OccurrencesTableUpdateCompanionBuilder = OccurrencesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> deviceId,
  Value<DateTime?> deletedAt,
  Value<String> reminderId,
  Value<String> occurrenceKey,
  Value<OccurrenceState> state,
  Value<String?> overrideStart,
  Value<String?> overrideEnd,
  Value<String?> overrideAlertPlan,
  Value<DateTime?> snoozedUntil,
  Value<DateTime?> resolvedAt,
  Value<String> alertsSent,
  Value<int> rowid,
});

final class $$OccurrencesTableReferences extends BaseReferences<_$AppDatabase, $OccurrencesTable, OccurrenceRow> {
  $$OccurrencesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $RemindersTable _reminderIdTable(_$AppDatabase db) =>
      db.reminders.createAlias('occurrences__reminder_id__reminders__id');

  $$RemindersTableProcessedTableManager get reminderId {
    final $_column = $_itemColumn<String>('reminder_id')!;

    final manager = $$RemindersTableTableManager($_db, $_db.reminders).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_reminderIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$OccurrencesTableFilterComposer extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get occurrenceKey =>
      $composableBuilder(column: $table.occurrenceKey, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<OccurrenceState, OccurrenceState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get overrideStart =>
      $composableBuilder(column: $table.overrideStart, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overrideEnd =>
      $composableBuilder(column: $table.overrideEnd, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get overrideAlertPlan =>
      $composableBuilder(column: $table.overrideAlertPlan, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get snoozedUntil =>
      $composableBuilder(column: $table.snoozedUntil, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get resolvedAt =>
      $composableBuilder(column: $table.resolvedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alertsSent =>
      $composableBuilder(column: $table.alertsSent, builder: (column) => ColumnFilters(column));

  $$RemindersTableFilterComposer get reminderId {
    final $$RemindersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RemindersTableFilterComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableOrderingComposer extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get occurrenceKey =>
      $composableBuilder(column: $table.occurrenceKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overrideStart =>
      $composableBuilder(column: $table.overrideStart, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overrideEnd =>
      $composableBuilder(column: $table.overrideEnd, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get overrideAlertPlan =>
      $composableBuilder(column: $table.overrideAlertPlan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get snoozedUntil =>
      $composableBuilder(column: $table.snoozedUntil, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get resolvedAt =>
      $composableBuilder(column: $table.resolvedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alertsSent =>
      $composableBuilder(column: $table.alertsSent, builder: (column) => ColumnOrderings(column));

  $$RemindersTableOrderingComposer get reminderId {
    final $$RemindersTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RemindersTableOrderingComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableAnnotationComposer extends Composer<_$AppDatabase, $OccurrencesTable> {
  $$OccurrencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId => $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get occurrenceKey =>
      $composableBuilder(column: $table.occurrenceKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<OccurrenceState, String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get overrideStart =>
      $composableBuilder(column: $table.overrideStart, builder: (column) => column);

  GeneratedColumn<String> get overrideEnd =>
      $composableBuilder(column: $table.overrideEnd, builder: (column) => column);

  GeneratedColumn<String> get overrideAlertPlan =>
      $composableBuilder(column: $table.overrideAlertPlan, builder: (column) => column);

  GeneratedColumn<DateTime> get snoozedUntil =>
      $composableBuilder(column: $table.snoozedUntil, builder: (column) => column);

  GeneratedColumn<DateTime> get resolvedAt =>
      $composableBuilder(column: $table.resolvedAt, builder: (column) => column);

  GeneratedColumn<String> get alertsSent => $composableBuilder(column: $table.alertsSent, builder: (column) => column);

  $$RemindersTableAnnotationComposer get reminderId {
    final $$RemindersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.reminderId,
      referencedTable: $db.reminders,
      getReferencedColumn: (t) => t.id,
      builder: (joinBuilder, {$addJoinBuilderToRootComposer, $removeJoinBuilderFromRootComposer}) =>
          $$RemindersTableAnnotationComposer(
            $db: $db,
            $table: $db.reminders,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer: $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$OccurrencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $OccurrencesTable,
          OccurrenceRow,
          $$OccurrencesTableFilterComposer,
          $$OccurrencesTableOrderingComposer,
          $$OccurrencesTableAnnotationComposer,
          $$OccurrencesTableCreateCompanionBuilder,
          $$OccurrencesTableUpdateCompanionBuilder,
          (OccurrenceRow, $$OccurrencesTableReferences),
          OccurrenceRow,
          PrefetchHooks Function({bool reminderId})
        > {
  $$OccurrencesTableTableManager(_$AppDatabase db, $OccurrencesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$OccurrencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$OccurrencesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$OccurrencesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> reminderId = const Value.absent(),
                Value<String> occurrenceKey = const Value.absent(),
                Value<OccurrenceState> state = const Value.absent(),
                Value<String?> overrideStart = const Value.absent(),
                Value<String?> overrideEnd = const Value.absent(),
                Value<String?> overrideAlertPlan = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String> alertsSent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrencesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deletedAt: deletedAt,
                reminderId: reminderId,
                occurrenceKey: occurrenceKey,
                state: state,
                overrideStart: overrideStart,
                overrideEnd: overrideEnd,
                overrideAlertPlan: overrideAlertPlan,
                snoozedUntil: snoozedUntil,
                resolvedAt: resolvedAt,
                alertsSent: alertsSent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String deviceId,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String reminderId,
                required String occurrenceKey,
                required OccurrenceState state,
                Value<String?> overrideStart = const Value.absent(),
                Value<String?> overrideEnd = const Value.absent(),
                Value<String?> overrideAlertPlan = const Value.absent(),
                Value<DateTime?> snoozedUntil = const Value.absent(),
                Value<DateTime?> resolvedAt = const Value.absent(),
                Value<String> alertsSent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => OccurrencesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deletedAt: deletedAt,
                reminderId: reminderId,
                occurrenceKey: occurrenceKey,
                state: state,
                overrideStart: overrideStart,
                overrideEnd: overrideEnd,
                overrideAlertPlan: overrideAlertPlan,
                snoozedUntil: snoozedUntil,
                resolvedAt: resolvedAt,
                alertsSent: alertsSent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable<$OccurrencesTable, OccurrenceRow>(table), $$OccurrencesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({reminderId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (reminderId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.reminderId,
                        referencedTable: $$OccurrencesTableReferences._reminderIdTable(db),
                        referencedColumn: $$OccurrencesTableReferences._reminderIdTable(db).id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$OccurrencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $OccurrencesTable,
      OccurrenceRow,
      $$OccurrencesTableFilterComposer,
      $$OccurrencesTableOrderingComposer,
      $$OccurrencesTableAnnotationComposer,
      $$OccurrencesTableCreateCompanionBuilder,
      $$OccurrencesTableUpdateCompanionBuilder,
      (OccurrenceRow, $$OccurrencesTableReferences),
      OccurrenceRow,
      PrefetchHooks Function({bool reminderId})
    >;
typedef $$CalendarOverlaysTableCreateCompanionBuilder = CalendarOverlaysCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String deviceId,
  Value<DateTime?> deletedAt,
  required String calendarId,
  required String eventId,
  Value<String?> seriesId,
  required String alertPlan,
  Value<Kind?> kindOverride,
  Value<ReminderContext?> contextOverride,
  required String scope,
  Value<DateTime?> orphanedAt,
  Value<int> rowid,
});
typedef $$CalendarOverlaysTableUpdateCompanionBuilder = CalendarOverlaysCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> deviceId,
  Value<DateTime?> deletedAt,
  Value<String> calendarId,
  Value<String> eventId,
  Value<String?> seriesId,
  Value<String> alertPlan,
  Value<Kind?> kindOverride,
  Value<ReminderContext?> contextOverride,
  Value<String> scope,
  Value<DateTime?> orphanedAt,
  Value<int> rowid,
});

class $$CalendarOverlaysTableFilterComposer extends Composer<_$AppDatabase, $CalendarOverlaysTable> {
  $$CalendarOverlaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get calendarId =>
      $composableBuilder(column: $table.calendarId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get alertPlan =>
      $composableBuilder(column: $table.alertPlan, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<Kind?, Kind, String> get kindOverride =>
      $composableBuilder(column: $table.kindOverride, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<ReminderContext?, ReminderContext, String> get contextOverride =>
      $composableBuilder(column: $table.contextOverride, builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get orphanedAt =>
      $composableBuilder(column: $table.orphanedAt, builder: (column) => ColumnFilters(column));
}

class $$CalendarOverlaysTableOrderingComposer extends Composer<_$AppDatabase, $CalendarOverlaysTable> {
  $$CalendarOverlaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get deviceId =>
      $composableBuilder(column: $table.deviceId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get calendarId =>
      $composableBuilder(column: $table.calendarId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seriesId =>
      $composableBuilder(column: $table.seriesId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get alertPlan =>
      $composableBuilder(column: $table.alertPlan, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get kindOverride =>
      $composableBuilder(column: $table.kindOverride, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contextOverride =>
      $composableBuilder(column: $table.contextOverride, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get scope =>
      $composableBuilder(column: $table.scope, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get orphanedAt =>
      $composableBuilder(column: $table.orphanedAt, builder: (column) => ColumnOrderings(column));
}

class $$CalendarOverlaysTableAnnotationComposer extends Composer<_$AppDatabase, $CalendarOverlaysTable> {
  $$CalendarOverlaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt => $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get deviceId => $composableBuilder(column: $table.deviceId, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt => $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get calendarId => $composableBuilder(column: $table.calendarId, builder: (column) => column);

  GeneratedColumn<String> get eventId => $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get seriesId => $composableBuilder(column: $table.seriesId, builder: (column) => column);

  GeneratedColumn<String> get alertPlan => $composableBuilder(column: $table.alertPlan, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Kind?, String> get kindOverride =>
      $composableBuilder(column: $table.kindOverride, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ReminderContext?, String> get contextOverride =>
      $composableBuilder(column: $table.contextOverride, builder: (column) => column);

  GeneratedColumn<String> get scope => $composableBuilder(column: $table.scope, builder: (column) => column);

  GeneratedColumn<DateTime> get orphanedAt =>
      $composableBuilder(column: $table.orphanedAt, builder: (column) => column);
}

class $$CalendarOverlaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarOverlaysTable,
          CalendarOverlayRow,
          $$CalendarOverlaysTableFilterComposer,
          $$CalendarOverlaysTableOrderingComposer,
          $$CalendarOverlaysTableAnnotationComposer,
          $$CalendarOverlaysTableCreateCompanionBuilder,
          $$CalendarOverlaysTableUpdateCompanionBuilder,
          (CalendarOverlayRow, BaseReferences<_$AppDatabase, $CalendarOverlaysTable, CalendarOverlayRow>),
          CalendarOverlayRow,
          PrefetchHooks Function()
        > {
  $$CalendarOverlaysTableTableManager(_$AppDatabase db, $CalendarOverlaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CalendarOverlaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CalendarOverlaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$CalendarOverlaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> deviceId = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String> calendarId = const Value.absent(),
                Value<String> eventId = const Value.absent(),
                Value<String?> seriesId = const Value.absent(),
                Value<String> alertPlan = const Value.absent(),
                Value<Kind?> kindOverride = const Value.absent(),
                Value<ReminderContext?> contextOverride = const Value.absent(),
                Value<String> scope = const Value.absent(),
                Value<DateTime?> orphanedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarOverlaysCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deletedAt: deletedAt,
                calendarId: calendarId,
                eventId: eventId,
                seriesId: seriesId,
                alertPlan: alertPlan,
                kindOverride: kindOverride,
                contextOverride: contextOverride,
                scope: scope,
                orphanedAt: orphanedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String deviceId,
                Value<DateTime?> deletedAt = const Value.absent(),
                required String calendarId,
                required String eventId,
                Value<String?> seriesId = const Value.absent(),
                required String alertPlan,
                Value<Kind?> kindOverride = const Value.absent(),
                Value<ReminderContext?> contextOverride = const Value.absent(),
                required String scope,
                Value<DateTime?> orphanedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarOverlaysCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deviceId: deviceId,
                deletedAt: deletedAt,
                calendarId: calendarId,
                eventId: eventId,
                seriesId: seriesId,
                alertPlan: alertPlan,
                kindOverride: kindOverride,
                contextOverride: contextOverride,
                scope: scope,
                orphanedAt: orphanedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarOverlaysTable, CalendarOverlayRow>(table),
                  BaseReferences<_$AppDatabase, $CalendarOverlaysTable, CalendarOverlayRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CalendarOverlaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarOverlaysTable,
      CalendarOverlayRow,
      $$CalendarOverlaysTableFilterComposer,
      $$CalendarOverlaysTableOrderingComposer,
      $$CalendarOverlaysTableAnnotationComposer,
      $$CalendarOverlaysTableCreateCompanionBuilder,
      $$CalendarOverlaysTableUpdateCompanionBuilder,
      (CalendarOverlayRow, BaseReferences<_$AppDatabase, $CalendarOverlaysTable, CalendarOverlayRow>),
      CalendarOverlayRow,
      PrefetchHooks Function()
    >;
typedef $$PrefsTableCreateCompanionBuilder = PrefsCompanion Function({
  required String key,
  required String value,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$PrefsTableUpdateCompanionBuilder = PrefsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

class $$PrefsTableFilterComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnFilters(column));
}

class $$PrefsTableOrderingComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$PrefsTableAnnotationComposer extends Composer<_$AppDatabase, $PrefsTable> {
  $$PrefsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key => $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value => $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt => $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$PrefsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrefsTable,
          PrefRow,
          $$PrefsTableFilterComposer,
          $$PrefsTableOrderingComposer,
          $$PrefsTableAnnotationComposer,
          $$PrefsTableCreateCompanionBuilder,
          $$PrefsTableUpdateCompanionBuilder,
          (PrefRow, BaseReferences<_$AppDatabase, $PrefsTable, PrefRow>),
          PrefRow,
          PrefetchHooks Function()
        > {
  $$PrefsTableTableManager(_$AppDatabase db, $PrefsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$PrefsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$PrefsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$PrefsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<DateTime> updatedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion(key: key, value: value, updatedAt: updatedAt, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            required DateTime updatedAt,
            Value<int> rowid = const Value.absent(),
          }) => PrefsCompanion.insert(key: key, value: value, updatedAt: updatedAt, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrefsTable, PrefRow>(table),
                  BaseReferences<_$AppDatabase, $PrefsTable, PrefRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrefsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrefsTable,
      PrefRow,
      $$PrefsTableFilterComposer,
      $$PrefsTableOrderingComposer,
      $$PrefsTableAnnotationComposer,
      $$PrefsTableCreateCompanionBuilder,
      $$PrefsTableUpdateCompanionBuilder,
      (PrefRow, BaseReferences<_$AppDatabase, $PrefsTable, PrefRow>),
      PrefRow,
      PrefetchHooks Function()
    >;
typedef $$MetricsQueueTableCreateCompanionBuilder = MetricsQueueCompanion Function({
  Value<int> id,
  required String name,
  required String props,
  required DateTime at,
});
typedef $$MetricsQueueTableUpdateCompanionBuilder = MetricsQueueCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String> props,
  Value<DateTime> at,
});

class $$MetricsQueueTableFilterComposer extends Composer<_$AppDatabase, $MetricsQueueTable> {
  $$MetricsQueueTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get props =>
      $composableBuilder(column: $table.props, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => ColumnFilters(column));
}

class $$MetricsQueueTableOrderingComposer extends Composer<_$AppDatabase, $MetricsQueueTable> {
  $$MetricsQueueTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get props =>
      $composableBuilder(column: $table.props, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get at =>
      $composableBuilder(column: $table.at, builder: (column) => ColumnOrderings(column));
}

class $$MetricsQueueTableAnnotationComposer extends Composer<_$AppDatabase, $MetricsQueueTable> {
  $$MetricsQueueTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id => $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name => $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get props => $composableBuilder(column: $table.props, builder: (column) => column);

  GeneratedColumn<DateTime> get at => $composableBuilder(column: $table.at, builder: (column) => column);
}

class $$MetricsQueueTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MetricsQueueTable,
          MetricRow,
          $$MetricsQueueTableFilterComposer,
          $$MetricsQueueTableOrderingComposer,
          $$MetricsQueueTableAnnotationComposer,
          $$MetricsQueueTableCreateCompanionBuilder,
          $$MetricsQueueTableUpdateCompanionBuilder,
          (MetricRow, BaseReferences<_$AppDatabase, $MetricsQueueTable, MetricRow>),
          MetricRow,
          PrefetchHooks Function()
        > {
  $$MetricsQueueTableTableManager(_$AppDatabase db, $MetricsQueueTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$MetricsQueueTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$MetricsQueueTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () => $$MetricsQueueTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> props = const Value.absent(),
            Value<DateTime> at = const Value.absent(),
          }) => MetricsQueueCompanion(id: id, name: name, props: props, at: at),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            required String props,
            required DateTime at,
          }) => MetricsQueueCompanion.insert(id: id, name: name, props: props, at: at),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MetricsQueueTable, MetricRow>(table),
                  BaseReferences<_$AppDatabase, $MetricsQueueTable, MetricRow>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$MetricsQueueTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MetricsQueueTable,
      MetricRow,
      $$MetricsQueueTableFilterComposer,
      $$MetricsQueueTableOrderingComposer,
      $$MetricsQueueTableAnnotationComposer,
      $$MetricsQueueTableCreateCompanionBuilder,
      $$MetricsQueueTableUpdateCompanionBuilder,
      (MetricRow, BaseReferences<_$AppDatabase, $MetricsQueueTable, MetricRow>),
      MetricRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$RemindersTableTableManager get reminders => $$RemindersTableTableManager(_db, _db.reminders);
  $$OccurrencesTableTableManager get occurrences => $$OccurrencesTableTableManager(_db, _db.occurrences);
  $$CalendarOverlaysTableTableManager get calendarOverlays =>
      $$CalendarOverlaysTableTableManager(_db, _db.calendarOverlays);
  $$PrefsTableTableManager get prefs => $$PrefsTableTableManager(_db, _db.prefs);
  $$MetricsQueueTableTableManager get metricsQueue => $$MetricsQueueTableTableManager(_db, _db.metricsQueue);
}
