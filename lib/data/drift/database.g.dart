// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
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
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    category,
    archived,
    startDate,
    endDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      ),
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class GoalRow extends DataClass implements Insertable<GoalRow> {
  final String id;
  final String name;
  final String? description;
  final String? category;
  final bool archived;
  final String startDate;
  final String? endDate;
  const GoalRow({
    required this.id,
    required this.name,
    this.description,
    this.category,
    required this.archived,
    required this.startDate,
    this.endDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    map['archived'] = Variable<bool>(archived);
    map['start_date'] = Variable<String>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<String>(endDate);
    }
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      archived: Value(archived),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
    );
  }

  factory GoalRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String?>(json['category']),
      archived: serializer.fromJson<bool>(json['archived']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String?>(json['endDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String?>(category),
      'archived': serializer.toJson<bool>(archived),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String?>(endDate),
    };
  }

  GoalRow copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> category = const Value.absent(),
    bool? archived,
    String? startDate,
    Value<String?> endDate = const Value.absent(),
  }) => GoalRow(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    category: category.present ? category.value : this.category,
    archived: archived ?? this.archived,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
  );
  GoalRow copyWithCompanion(GoalsCompanion data) {
    return GoalRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      archived: data.archived.present ? data.archived.value : this.archived,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('archived: $archived, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    category,
    archived,
    startDate,
    endDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.category == this.category &&
          other.archived == this.archived &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate);
}

class GoalsCompanion extends UpdateCompanion<GoalRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> category;
  final Value<bool> archived;
  final Value<String> startDate;
  final Value<String?> endDate;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.archived = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.archived = const Value.absent(),
    required String startDate,
    this.endDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       startDate = Value(startDate);
  static Insertable<GoalRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? category,
    Expression<bool>? archived,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (archived != null) 'archived': archived,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? category,
    Value<bool>? archived,
    Value<String>? startDate,
    Value<String?>? endDate,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      archived: archived ?? this.archived,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('archived: $archived, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalVersionsTable extends GoalVersions
    with TableInfo<$GoalVersionsTable, GoalVersionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalVersionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  static const VerificationMeta _versionStartDateMeta = const VerificationMeta(
    'versionStartDate',
  );
  @override
  late final GeneratedColumn<String> versionStartDate = GeneratedColumn<String>(
    'version_start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _evaluationPeriodMeta = const VerificationMeta(
    'evaluationPeriod',
  );
  @override
  late final GeneratedColumn<String> evaluationPeriod = GeneratedColumn<String>(
    'evaluation_period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eligibleDaysRuleMeta = const VerificationMeta(
    'eligibleDaysRule',
  );
  @override
  late final GeneratedColumn<String> eligibleDaysRule = GeneratedColumn<String>(
    'eligible_days_rule',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetComparisonMeta = const VerificationMeta(
    'targetComparison',
  );
  @override
  late final GeneratedColumn<String> targetComparison = GeneratedColumn<String>(
    'target_comparison',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetValueMeta = const VerificationMeta(
    'targetValue',
  );
  @override
  late final GeneratedColumn<String> targetValue = GeneratedColumn<String>(
    'target_value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _trackingTypeMeta = const VerificationMeta(
    'trackingType',
  );
  @override
  late final GeneratedColumn<String> trackingType = GeneratedColumn<String>(
    'tracking_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cheatDayQuotaMeta = const VerificationMeta(
    'cheatDayQuota',
  );
  @override
  late final GeneratedColumn<int> cheatDayQuota = GeneratedColumn<int>(
    'cheat_day_quota',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isPausedMeta = const VerificationMeta(
    'isPaused',
  );
  @override
  late final GeneratedColumn<bool> isPaused = GeneratedColumn<bool>(
    'is_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    versionStartDate,
    evaluationPeriod,
    eligibleDaysRule,
    targetComparison,
    targetValue,
    trackingType,
    cheatDayQuota,
    isPaused,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_versions';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalVersionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('version_start_date')) {
      context.handle(
        _versionStartDateMeta,
        versionStartDate.isAcceptableOrUnknown(
          data['version_start_date']!,
          _versionStartDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_versionStartDateMeta);
    }
    if (data.containsKey('evaluation_period')) {
      context.handle(
        _evaluationPeriodMeta,
        evaluationPeriod.isAcceptableOrUnknown(
          data['evaluation_period']!,
          _evaluationPeriodMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_evaluationPeriodMeta);
    }
    if (data.containsKey('eligible_days_rule')) {
      context.handle(
        _eligibleDaysRuleMeta,
        eligibleDaysRule.isAcceptableOrUnknown(
          data['eligible_days_rule']!,
          _eligibleDaysRuleMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_eligibleDaysRuleMeta);
    }
    if (data.containsKey('target_comparison')) {
      context.handle(
        _targetComparisonMeta,
        targetComparison.isAcceptableOrUnknown(
          data['target_comparison']!,
          _targetComparisonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetComparisonMeta);
    }
    if (data.containsKey('target_value')) {
      context.handle(
        _targetValueMeta,
        targetValue.isAcceptableOrUnknown(
          data['target_value']!,
          _targetValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetValueMeta);
    }
    if (data.containsKey('tracking_type')) {
      context.handle(
        _trackingTypeMeta,
        trackingType.isAcceptableOrUnknown(
          data['tracking_type']!,
          _trackingTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_trackingTypeMeta);
    }
    if (data.containsKey('cheat_day_quota')) {
      context.handle(
        _cheatDayQuotaMeta,
        cheatDayQuota.isAcceptableOrUnknown(
          data['cheat_day_quota']!,
          _cheatDayQuotaMeta,
        ),
      );
    }
    if (data.containsKey('is_paused')) {
      context.handle(
        _isPausedMeta,
        isPaused.isAcceptableOrUnknown(data['is_paused']!, _isPausedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalVersionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalVersionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      versionStartDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}version_start_date'],
      )!,
      evaluationPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}evaluation_period'],
      )!,
      eligibleDaysRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}eligible_days_rule'],
      )!,
      targetComparison: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_comparison'],
      )!,
      targetValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_value'],
      )!,
      trackingType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tracking_type'],
      )!,
      cheatDayQuota: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cheat_day_quota'],
      )!,
      isPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_paused'],
      )!,
    );
  }

  @override
  $GoalVersionsTable createAlias(String alias) {
    return $GoalVersionsTable(attachedDatabase, alias);
  }
}

class GoalVersionRow extends DataClass implements Insertable<GoalVersionRow> {
  final String id;
  final String goalId;
  final String versionStartDate;
  final String evaluationPeriod;
  final String eligibleDaysRule;
  final String targetComparison;
  final String targetValue;
  final String trackingType;
  final int cheatDayQuota;
  final bool isPaused;
  const GoalVersionRow({
    required this.id,
    required this.goalId,
    required this.versionStartDate,
    required this.evaluationPeriod,
    required this.eligibleDaysRule,
    required this.targetComparison,
    required this.targetValue,
    required this.trackingType,
    required this.cheatDayQuota,
    required this.isPaused,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['version_start_date'] = Variable<String>(versionStartDate);
    map['evaluation_period'] = Variable<String>(evaluationPeriod);
    map['eligible_days_rule'] = Variable<String>(eligibleDaysRule);
    map['target_comparison'] = Variable<String>(targetComparison);
    map['target_value'] = Variable<String>(targetValue);
    map['tracking_type'] = Variable<String>(trackingType);
    map['cheat_day_quota'] = Variable<int>(cheatDayQuota);
    map['is_paused'] = Variable<bool>(isPaused);
    return map;
  }

  GoalVersionsCompanion toCompanion(bool nullToAbsent) {
    return GoalVersionsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      versionStartDate: Value(versionStartDate),
      evaluationPeriod: Value(evaluationPeriod),
      eligibleDaysRule: Value(eligibleDaysRule),
      targetComparison: Value(targetComparison),
      targetValue: Value(targetValue),
      trackingType: Value(trackingType),
      cheatDayQuota: Value(cheatDayQuota),
      isPaused: Value(isPaused),
    );
  }

  factory GoalVersionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalVersionRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      versionStartDate: serializer.fromJson<String>(json['versionStartDate']),
      evaluationPeriod: serializer.fromJson<String>(json['evaluationPeriod']),
      eligibleDaysRule: serializer.fromJson<String>(json['eligibleDaysRule']),
      targetComparison: serializer.fromJson<String>(json['targetComparison']),
      targetValue: serializer.fromJson<String>(json['targetValue']),
      trackingType: serializer.fromJson<String>(json['trackingType']),
      cheatDayQuota: serializer.fromJson<int>(json['cheatDayQuota']),
      isPaused: serializer.fromJson<bool>(json['isPaused']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'versionStartDate': serializer.toJson<String>(versionStartDate),
      'evaluationPeriod': serializer.toJson<String>(evaluationPeriod),
      'eligibleDaysRule': serializer.toJson<String>(eligibleDaysRule),
      'targetComparison': serializer.toJson<String>(targetComparison),
      'targetValue': serializer.toJson<String>(targetValue),
      'trackingType': serializer.toJson<String>(trackingType),
      'cheatDayQuota': serializer.toJson<int>(cheatDayQuota),
      'isPaused': serializer.toJson<bool>(isPaused),
    };
  }

  GoalVersionRow copyWith({
    String? id,
    String? goalId,
    String? versionStartDate,
    String? evaluationPeriod,
    String? eligibleDaysRule,
    String? targetComparison,
    String? targetValue,
    String? trackingType,
    int? cheatDayQuota,
    bool? isPaused,
  }) => GoalVersionRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    versionStartDate: versionStartDate ?? this.versionStartDate,
    evaluationPeriod: evaluationPeriod ?? this.evaluationPeriod,
    eligibleDaysRule: eligibleDaysRule ?? this.eligibleDaysRule,
    targetComparison: targetComparison ?? this.targetComparison,
    targetValue: targetValue ?? this.targetValue,
    trackingType: trackingType ?? this.trackingType,
    cheatDayQuota: cheatDayQuota ?? this.cheatDayQuota,
    isPaused: isPaused ?? this.isPaused,
  );
  GoalVersionRow copyWithCompanion(GoalVersionsCompanion data) {
    return GoalVersionRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      versionStartDate: data.versionStartDate.present
          ? data.versionStartDate.value
          : this.versionStartDate,
      evaluationPeriod: data.evaluationPeriod.present
          ? data.evaluationPeriod.value
          : this.evaluationPeriod,
      eligibleDaysRule: data.eligibleDaysRule.present
          ? data.eligibleDaysRule.value
          : this.eligibleDaysRule,
      targetComparison: data.targetComparison.present
          ? data.targetComparison.value
          : this.targetComparison,
      targetValue: data.targetValue.present
          ? data.targetValue.value
          : this.targetValue,
      trackingType: data.trackingType.present
          ? data.trackingType.value
          : this.trackingType,
      cheatDayQuota: data.cheatDayQuota.present
          ? data.cheatDayQuota.value
          : this.cheatDayQuota,
      isPaused: data.isPaused.present ? data.isPaused.value : this.isPaused,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalVersionRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('versionStartDate: $versionStartDate, ')
          ..write('evaluationPeriod: $evaluationPeriod, ')
          ..write('eligibleDaysRule: $eligibleDaysRule, ')
          ..write('targetComparison: $targetComparison, ')
          ..write('targetValue: $targetValue, ')
          ..write('trackingType: $trackingType, ')
          ..write('cheatDayQuota: $cheatDayQuota, ')
          ..write('isPaused: $isPaused')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    versionStartDate,
    evaluationPeriod,
    eligibleDaysRule,
    targetComparison,
    targetValue,
    trackingType,
    cheatDayQuota,
    isPaused,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalVersionRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.versionStartDate == this.versionStartDate &&
          other.evaluationPeriod == this.evaluationPeriod &&
          other.eligibleDaysRule == this.eligibleDaysRule &&
          other.targetComparison == this.targetComparison &&
          other.targetValue == this.targetValue &&
          other.trackingType == this.trackingType &&
          other.cheatDayQuota == this.cheatDayQuota &&
          other.isPaused == this.isPaused);
}

class GoalVersionsCompanion extends UpdateCompanion<GoalVersionRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> versionStartDate;
  final Value<String> evaluationPeriod;
  final Value<String> eligibleDaysRule;
  final Value<String> targetComparison;
  final Value<String> targetValue;
  final Value<String> trackingType;
  final Value<int> cheatDayQuota;
  final Value<bool> isPaused;
  final Value<int> rowid;
  const GoalVersionsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.versionStartDate = const Value.absent(),
    this.evaluationPeriod = const Value.absent(),
    this.eligibleDaysRule = const Value.absent(),
    this.targetComparison = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.trackingType = const Value.absent(),
    this.cheatDayQuota = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalVersionsCompanion.insert({
    required String id,
    required String goalId,
    required String versionStartDate,
    required String evaluationPeriod,
    required String eligibleDaysRule,
    required String targetComparison,
    required String targetValue,
    required String trackingType,
    this.cheatDayQuota = const Value.absent(),
    this.isPaused = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       versionStartDate = Value(versionStartDate),
       evaluationPeriod = Value(evaluationPeriod),
       eligibleDaysRule = Value(eligibleDaysRule),
       targetComparison = Value(targetComparison),
       targetValue = Value(targetValue),
       trackingType = Value(trackingType);
  static Insertable<GoalVersionRow> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? versionStartDate,
    Expression<String>? evaluationPeriod,
    Expression<String>? eligibleDaysRule,
    Expression<String>? targetComparison,
    Expression<String>? targetValue,
    Expression<String>? trackingType,
    Expression<int>? cheatDayQuota,
    Expression<bool>? isPaused,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (versionStartDate != null) 'version_start_date': versionStartDate,
      if (evaluationPeriod != null) 'evaluation_period': evaluationPeriod,
      if (eligibleDaysRule != null) 'eligible_days_rule': eligibleDaysRule,
      if (targetComparison != null) 'target_comparison': targetComparison,
      if (targetValue != null) 'target_value': targetValue,
      if (trackingType != null) 'tracking_type': trackingType,
      if (cheatDayQuota != null) 'cheat_day_quota': cheatDayQuota,
      if (isPaused != null) 'is_paused': isPaused,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalVersionsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? versionStartDate,
    Value<String>? evaluationPeriod,
    Value<String>? eligibleDaysRule,
    Value<String>? targetComparison,
    Value<String>? targetValue,
    Value<String>? trackingType,
    Value<int>? cheatDayQuota,
    Value<bool>? isPaused,
    Value<int>? rowid,
  }) {
    return GoalVersionsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      versionStartDate: versionStartDate ?? this.versionStartDate,
      evaluationPeriod: evaluationPeriod ?? this.evaluationPeriod,
      eligibleDaysRule: eligibleDaysRule ?? this.eligibleDaysRule,
      targetComparison: targetComparison ?? this.targetComparison,
      targetValue: targetValue ?? this.targetValue,
      trackingType: trackingType ?? this.trackingType,
      cheatDayQuota: cheatDayQuota ?? this.cheatDayQuota,
      isPaused: isPaused ?? this.isPaused,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (versionStartDate.present) {
      map['version_start_date'] = Variable<String>(versionStartDate.value);
    }
    if (evaluationPeriod.present) {
      map['evaluation_period'] = Variable<String>(evaluationPeriod.value);
    }
    if (eligibleDaysRule.present) {
      map['eligible_days_rule'] = Variable<String>(eligibleDaysRule.value);
    }
    if (targetComparison.present) {
      map['target_comparison'] = Variable<String>(targetComparison.value);
    }
    if (targetValue.present) {
      map['target_value'] = Variable<String>(targetValue.value);
    }
    if (trackingType.present) {
      map['tracking_type'] = Variable<String>(trackingType.value);
    }
    if (cheatDayQuota.present) {
      map['cheat_day_quota'] = Variable<int>(cheatDayQuota.value);
    }
    if (isPaused.present) {
      map['is_paused'] = Variable<bool>(isPaused.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalVersionsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('versionStartDate: $versionStartDate, ')
          ..write('evaluationPeriod: $evaluationPeriod, ')
          ..write('eligibleDaysRule: $eligibleDaysRule, ')
          ..write('targetComparison: $targetComparison, ')
          ..write('targetValue: $targetValue, ')
          ..write('trackingType: $trackingType, ')
          ..write('cheatDayQuota: $cheatDayQuota, ')
          ..write('isPaused: $isPaused, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalLogsTable extends GoalLogs
    with TableInfo<$GoalLogsTable, GoalLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<String> timestamp = GeneratedColumn<String>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _dnfMarkedMeta = const VerificationMeta(
    'dnfMarked',
  );
  @override
  late final GeneratedColumn<bool> dnfMarked = GeneratedColumn<bool>(
    'dnf_marked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("dnf_marked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    goalId,
    date,
    timestamp,
    value,
    completed,
    dnfMarked,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goal_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    } else if (isInserting) {
      context.missing(_completedMeta);
    }
    if (data.containsKey('dnf_marked')) {
      context.handle(
        _dnfMarkedMeta,
        dnfMarked.isAcceptableOrUnknown(data['dnf_marked']!, _dnfMarkedMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalLogRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timestamp'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      dnfMarked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}dnf_marked'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $GoalLogsTable createAlias(String alias) {
    return $GoalLogsTable(attachedDatabase, alias);
  }
}

class GoalLogRow extends DataClass implements Insertable<GoalLogRow> {
  final String id;
  final String goalId;
  final String date;
  final String timestamp;
  final double value;
  final bool completed;
  final bool dnfMarked;
  final String? note;
  const GoalLogRow({
    required this.id,
    required this.goalId,
    required this.date,
    required this.timestamp,
    required this.value,
    required this.completed,
    required this.dnfMarked,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['date'] = Variable<String>(date);
    map['timestamp'] = Variable<String>(timestamp);
    map['value'] = Variable<double>(value);
    map['completed'] = Variable<bool>(completed);
    map['dnf_marked'] = Variable<bool>(dnfMarked);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  GoalLogsCompanion toCompanion(bool nullToAbsent) {
    return GoalLogsCompanion(
      id: Value(id),
      goalId: Value(goalId),
      date: Value(date),
      timestamp: Value(timestamp),
      value: Value(value),
      completed: Value(completed),
      dnfMarked: Value(dnfMarked),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory GoalLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalLogRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      date: serializer.fromJson<String>(json['date']),
      timestamp: serializer.fromJson<String>(json['timestamp']),
      value: serializer.fromJson<double>(json['value']),
      completed: serializer.fromJson<bool>(json['completed']),
      dnfMarked: serializer.fromJson<bool>(json['dnfMarked']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'date': serializer.toJson<String>(date),
      'timestamp': serializer.toJson<String>(timestamp),
      'value': serializer.toJson<double>(value),
      'completed': serializer.toJson<bool>(completed),
      'dnfMarked': serializer.toJson<bool>(dnfMarked),
      'note': serializer.toJson<String?>(note),
    };
  }

  GoalLogRow copyWith({
    String? id,
    String? goalId,
    String? date,
    String? timestamp,
    double? value,
    bool? completed,
    bool? dnfMarked,
    Value<String?> note = const Value.absent(),
  }) => GoalLogRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    date: date ?? this.date,
    timestamp: timestamp ?? this.timestamp,
    value: value ?? this.value,
    completed: completed ?? this.completed,
    dnfMarked: dnfMarked ?? this.dnfMarked,
    note: note.present ? note.value : this.note,
  );
  GoalLogRow copyWithCompanion(GoalLogsCompanion data) {
    return GoalLogRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      date: data.date.present ? data.date.value : this.date,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      value: data.value.present ? data.value.value : this.value,
      completed: data.completed.present ? data.completed.value : this.completed,
      dnfMarked: data.dnfMarked.present ? data.dnfMarked.value : this.dnfMarked,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalLogRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('timestamp: $timestamp, ')
          ..write('value: $value, ')
          ..write('completed: $completed, ')
          ..write('dnfMarked: $dnfMarked, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    goalId,
    date,
    timestamp,
    value,
    completed,
    dnfMarked,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalLogRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.date == this.date &&
          other.timestamp == this.timestamp &&
          other.value == this.value &&
          other.completed == this.completed &&
          other.dnfMarked == this.dnfMarked &&
          other.note == this.note);
}

class GoalLogsCompanion extends UpdateCompanion<GoalLogRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> date;
  final Value<String> timestamp;
  final Value<double> value;
  final Value<bool> completed;
  final Value<bool> dnfMarked;
  final Value<String?> note;
  final Value<int> rowid;
  const GoalLogsCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.date = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.value = const Value.absent(),
    this.completed = const Value.absent(),
    this.dnfMarked = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalLogsCompanion.insert({
    required String id,
    required String goalId,
    required String date,
    required String timestamp,
    required double value,
    required bool completed,
    this.dnfMarked = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       date = Value(date),
       timestamp = Value(timestamp),
       value = Value(value),
       completed = Value(completed);
  static Insertable<GoalLogRow> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? date,
    Expression<String>? timestamp,
    Expression<double>? value,
    Expression<bool>? completed,
    Expression<bool>? dnfMarked,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (date != null) 'date': date,
      if (timestamp != null) 'timestamp': timestamp,
      if (value != null) 'value': value,
      if (completed != null) 'completed': completed,
      if (dnfMarked != null) 'dnf_marked': dnfMarked,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? date,
    Value<String>? timestamp,
    Value<double>? value,
    Value<bool>? completed,
    Value<bool>? dnfMarked,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return GoalLogsCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      timestamp: timestamp ?? this.timestamp,
      value: value ?? this.value,
      completed: completed ?? this.completed,
      dnfMarked: dnfMarked ?? this.dnfMarked,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<String>(timestamp.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (dnfMarked.present) {
      map['dnf_marked'] = Variable<bool>(dnfMarked.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalLogsCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('timestamp: $timestamp, ')
          ..write('value: $value, ')
          ..write('completed: $completed, ')
          ..write('dnfMarked: $dnfMarked, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BlackoutDatesTable extends BlackoutDates
    with TableInfo<$BlackoutDatesTable, BlackoutDateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BlackoutDatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reasonMeta = const VerificationMeta('reason');
  @override
  late final GeneratedColumn<String> reason = GeneratedColumn<String>(
    'reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, goalId, date, reason];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'blackout_dates';
  @override
  VerificationContext validateIntegrity(
    Insertable<BlackoutDateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('reason')) {
      context.handle(
        _reasonMeta,
        reason.isAcceptableOrUnknown(data['reason']!, _reasonMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BlackoutDateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BlackoutDateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      reason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reason'],
      ),
    );
  }

  @override
  $BlackoutDatesTable createAlias(String alias) {
    return $BlackoutDatesTable(attachedDatabase, alias);
  }
}

class BlackoutDateRow extends DataClass implements Insertable<BlackoutDateRow> {
  final String id;
  final String goalId;
  final String date;
  final String? reason;
  const BlackoutDateRow({
    required this.id,
    required this.goalId,
    required this.date,
    this.reason,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || reason != null) {
      map['reason'] = Variable<String>(reason);
    }
    return map;
  }

  BlackoutDatesCompanion toCompanion(bool nullToAbsent) {
    return BlackoutDatesCompanion(
      id: Value(id),
      goalId: Value(goalId),
      date: Value(date),
      reason: reason == null && nullToAbsent
          ? const Value.absent()
          : Value(reason),
    );
  }

  factory BlackoutDateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BlackoutDateRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      date: serializer.fromJson<String>(json['date']),
      reason: serializer.fromJson<String?>(json['reason']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'date': serializer.toJson<String>(date),
      'reason': serializer.toJson<String?>(reason),
    };
  }

  BlackoutDateRow copyWith({
    String? id,
    String? goalId,
    String? date,
    Value<String?> reason = const Value.absent(),
  }) => BlackoutDateRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    date: date ?? this.date,
    reason: reason.present ? reason.value : this.reason,
  );
  BlackoutDateRow copyWithCompanion(BlackoutDatesCompanion data) {
    return BlackoutDateRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      date: data.date.present ? data.date.value : this.date,
      reason: data.reason.present ? data.reason.value : this.reason,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BlackoutDateRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('reason: $reason')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, date, reason);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BlackoutDateRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.date == this.date &&
          other.reason == this.reason);
}

class BlackoutDatesCompanion extends UpdateCompanion<BlackoutDateRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> date;
  final Value<String?> reason;
  final Value<int> rowid;
  const BlackoutDatesCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.date = const Value.absent(),
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BlackoutDatesCompanion.insert({
    required String id,
    required String goalId,
    required String date,
    this.reason = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       date = Value(date);
  static Insertable<BlackoutDateRow> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? date,
    Expression<String>? reason,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (date != null) 'date': date,
      if (reason != null) 'reason': reason,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BlackoutDatesCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? date,
    Value<String?>? reason,
    Value<int>? rowid,
  }) {
    return BlackoutDatesCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      reason: reason ?? this.reason,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (reason.present) {
      map['reason'] = Variable<String>(reason.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BlackoutDatesCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('reason: $reason, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CheatDaysTable extends CheatDays
    with TableInfo<$CheatDaysTable, CheatDayRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheatDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, goalId, date, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cheat_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheatDayRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CheatDayRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheatDayRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $CheatDaysTable createAlias(String alias) {
    return $CheatDaysTable(attachedDatabase, alias);
  }
}

class CheatDayRow extends DataClass implements Insertable<CheatDayRow> {
  final String id;
  final String goalId;
  final String date;
  final String? note;
  const CheatDayRow({
    required this.id,
    required this.goalId,
    required this.date,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['goal_id'] = Variable<String>(goalId);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  CheatDaysCompanion toCompanion(bool nullToAbsent) {
    return CheatDaysCompanion(
      id: Value(id),
      goalId: Value(goalId),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory CheatDayRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheatDayRow(
      id: serializer.fromJson<String>(json['id']),
      goalId: serializer.fromJson<String>(json['goalId']),
      date: serializer.fromJson<String>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'goalId': serializer.toJson<String>(goalId),
      'date': serializer.toJson<String>(date),
      'note': serializer.toJson<String?>(note),
    };
  }

  CheatDayRow copyWith({
    String? id,
    String? goalId,
    String? date,
    Value<String?> note = const Value.absent(),
  }) => CheatDayRow(
    id: id ?? this.id,
    goalId: goalId ?? this.goalId,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
  );
  CheatDayRow copyWithCompanion(CheatDaysCompanion data) {
    return CheatDayRow(
      id: data.id.present ? data.id.value : this.id,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheatDayRow(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, goalId, date, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheatDayRow &&
          other.id == this.id &&
          other.goalId == this.goalId &&
          other.date == this.date &&
          other.note == this.note);
}

class CheatDaysCompanion extends UpdateCompanion<CheatDayRow> {
  final Value<String> id;
  final Value<String> goalId;
  final Value<String> date;
  final Value<String?> note;
  final Value<int> rowid;
  const CheatDaysCompanion({
    this.id = const Value.absent(),
    this.goalId = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CheatDaysCompanion.insert({
    required String id,
    required String goalId,
    required String date,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       goalId = Value(goalId),
       date = Value(date);
  static Insertable<CheatDayRow> custom({
    Expression<String>? id,
    Expression<String>? goalId,
    Expression<String>? date,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (goalId != null) 'goal_id': goalId,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CheatDaysCompanion copyWith({
    Value<String>? id,
    Value<String>? goalId,
    Value<String>? date,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return CheatDaysCompanion(
      id: id ?? this.id,
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheatDaysCompanion(')
          ..write('id: $id, ')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StatusCachesTable extends StatusCaches
    with TableInfo<$StatusCachesTable, StatusCacheRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatusCachesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES goals (id)',
    ),
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentValueMeta = const VerificationMeta(
    'currentValue',
  );
  @override
  late final GeneratedColumn<double> currentValue = GeneratedColumn<double>(
    'current_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetValueMeta = const VerificationMeta(
    'targetValue',
  );
  @override
  late final GeneratedColumn<double> targetValue = GeneratedColumn<double>(
    'target_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    goalId,
    date,
    status,
    currentValue,
    targetValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'status_caches';
  @override
  VerificationContext validateIntegrity(
    Insertable<StatusCacheRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_goalIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('current_value')) {
      context.handle(
        _currentValueMeta,
        currentValue.isAcceptableOrUnknown(
          data['current_value']!,
          _currentValueMeta,
        ),
      );
    }
    if (data.containsKey('target_value')) {
      context.handle(
        _targetValueMeta,
        targetValue.isAcceptableOrUnknown(
          data['target_value']!,
          _targetValueMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {goalId, date};
  @override
  StatusCacheRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StatusCacheRow(
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      currentValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}current_value'],
      ),
      targetValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}target_value'],
      ),
    );
  }

  @override
  $StatusCachesTable createAlias(String alias) {
    return $StatusCachesTable(attachedDatabase, alias);
  }
}

class StatusCacheRow extends DataClass implements Insertable<StatusCacheRow> {
  final String goalId;
  final String date;
  final String status;
  final double? currentValue;
  final double? targetValue;
  const StatusCacheRow({
    required this.goalId,
    required this.date,
    required this.status,
    this.currentValue,
    this.targetValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['goal_id'] = Variable<String>(goalId);
    map['date'] = Variable<String>(date);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || currentValue != null) {
      map['current_value'] = Variable<double>(currentValue);
    }
    if (!nullToAbsent || targetValue != null) {
      map['target_value'] = Variable<double>(targetValue);
    }
    return map;
  }

  StatusCachesCompanion toCompanion(bool nullToAbsent) {
    return StatusCachesCompanion(
      goalId: Value(goalId),
      date: Value(date),
      status: Value(status),
      currentValue: currentValue == null && nullToAbsent
          ? const Value.absent()
          : Value(currentValue),
      targetValue: targetValue == null && nullToAbsent
          ? const Value.absent()
          : Value(targetValue),
    );
  }

  factory StatusCacheRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StatusCacheRow(
      goalId: serializer.fromJson<String>(json['goalId']),
      date: serializer.fromJson<String>(json['date']),
      status: serializer.fromJson<String>(json['status']),
      currentValue: serializer.fromJson<double?>(json['currentValue']),
      targetValue: serializer.fromJson<double?>(json['targetValue']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'goalId': serializer.toJson<String>(goalId),
      'date': serializer.toJson<String>(date),
      'status': serializer.toJson<String>(status),
      'currentValue': serializer.toJson<double?>(currentValue),
      'targetValue': serializer.toJson<double?>(targetValue),
    };
  }

  StatusCacheRow copyWith({
    String? goalId,
    String? date,
    String? status,
    Value<double?> currentValue = const Value.absent(),
    Value<double?> targetValue = const Value.absent(),
  }) => StatusCacheRow(
    goalId: goalId ?? this.goalId,
    date: date ?? this.date,
    status: status ?? this.status,
    currentValue: currentValue.present ? currentValue.value : this.currentValue,
    targetValue: targetValue.present ? targetValue.value : this.targetValue,
  );
  StatusCacheRow copyWithCompanion(StatusCachesCompanion data) {
    return StatusCacheRow(
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      date: data.date.present ? data.date.value : this.date,
      status: data.status.present ? data.status.value : this.status,
      currentValue: data.currentValue.present
          ? data.currentValue.value
          : this.currentValue,
      targetValue: data.targetValue.present
          ? data.targetValue.value
          : this.targetValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StatusCacheRow(')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('currentValue: $currentValue, ')
          ..write('targetValue: $targetValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(goalId, date, status, currentValue, targetValue);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatusCacheRow &&
          other.goalId == this.goalId &&
          other.date == this.date &&
          other.status == this.status &&
          other.currentValue == this.currentValue &&
          other.targetValue == this.targetValue);
}

class StatusCachesCompanion extends UpdateCompanion<StatusCacheRow> {
  final Value<String> goalId;
  final Value<String> date;
  final Value<String> status;
  final Value<double?> currentValue;
  final Value<double?> targetValue;
  final Value<int> rowid;
  const StatusCachesCompanion({
    this.goalId = const Value.absent(),
    this.date = const Value.absent(),
    this.status = const Value.absent(),
    this.currentValue = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StatusCachesCompanion.insert({
    required String goalId,
    required String date,
    required String status,
    this.currentValue = const Value.absent(),
    this.targetValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : goalId = Value(goalId),
       date = Value(date),
       status = Value(status);
  static Insertable<StatusCacheRow> custom({
    Expression<String>? goalId,
    Expression<String>? date,
    Expression<String>? status,
    Expression<double>? currentValue,
    Expression<double>? targetValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (goalId != null) 'goal_id': goalId,
      if (date != null) 'date': date,
      if (status != null) 'status': status,
      if (currentValue != null) 'current_value': currentValue,
      if (targetValue != null) 'target_value': targetValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StatusCachesCompanion copyWith({
    Value<String>? goalId,
    Value<String>? date,
    Value<String>? status,
    Value<double?>? currentValue,
    Value<double?>? targetValue,
    Value<int>? rowid,
  }) {
    return StatusCachesCompanion(
      goalId: goalId ?? this.goalId,
      date: date ?? this.date,
      status: status ?? this.status,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (currentValue.present) {
      map['current_value'] = Variable<double>(currentValue.value);
    }
    if (targetValue.present) {
      map['target_value'] = Variable<double>(targetValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatusCachesCompanion(')
          ..write('goalId: $goalId, ')
          ..write('date: $date, ')
          ..write('status: $status, ')
          ..write('currentValue: $currentValue, ')
          ..write('targetValue: $targetValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $GoalVersionsTable goalVersions = $GoalVersionsTable(this);
  late final $GoalLogsTable goalLogs = $GoalLogsTable(this);
  late final $BlackoutDatesTable blackoutDates = $BlackoutDatesTable(this);
  late final $CheatDaysTable cheatDays = $CheatDaysTable(this);
  late final $StatusCachesTable statusCaches = $StatusCachesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    goals,
    goalVersions,
    goalLogs,
    blackoutDates,
    cheatDays,
    statusCaches,
  ];
}

typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  required String name,
  Value<String?> description,
  Value<String?> category,
  Value<bool> archived,
  required String startDate,
  Value<String?> endDate,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> description,
  Value<String?> category,
  Value<bool> archived,
  Value<String> startDate,
  Value<String?> endDate,
  Value<int> rowid,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, GoalRow> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$GoalVersionsTable, List<GoalVersionRow>>
  _goalVersionsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.goalVersions,
    aliasName: 'goals__id__goal_versions__goal_id',
  );

  $$GoalVersionsTableProcessedTableManager get goalVersionsRefs {
    final manager = $$GoalVersionsTableTableManager(
      $_db,
      $_db.goalVersions,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalVersionsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GoalLogsTable, List<GoalLogRow>>
  _goalLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.goalLogs,
    aliasName: 'goals__id__goal_logs__goal_id',
  );

  $$GoalLogsTableProcessedTableManager get goalLogsRefs {
    final manager = $$GoalLogsTableTableManager(
      $_db,
      $_db.goalLogs,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BlackoutDatesTable, List<BlackoutDateRow>>
  _blackoutDatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.blackoutDates,
    aliasName: 'goals__id__blackout_dates__goal_id',
  );

  $$BlackoutDatesTableProcessedTableManager get blackoutDatesRefs {
    final manager = $$BlackoutDatesTableTableManager(
      $_db,
      $_db.blackoutDates,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_blackoutDatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CheatDaysTable, List<CheatDayRow>>
  _cheatDaysRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.cheatDays,
    aliasName: 'goals__id__cheat_days__goal_id',
  );

  $$CheatDaysTableProcessedTableManager get cheatDaysRefs {
    final manager = $$CheatDaysTableTableManager(
      $_db,
      $_db.cheatDays,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_cheatDaysRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$StatusCachesTable, List<StatusCacheRow>>
  _statusCachesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.statusCaches,
    aliasName: 'goals__id__status_caches__goal_id',
  );

  $$StatusCachesTableProcessedTableManager get statusCachesRefs {
    final manager = $$StatusCachesTableTableManager(
      $_db,
      $_db.statusCaches,
    ).filter((f) => f.goalId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_statusCachesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> goalVersionsRefs(
    Expression<bool> Function($$GoalVersionsTableFilterComposer f) f,
  ) {
    final $$GoalVersionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalVersions,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalVersionsTableFilterComposer(
            $db: $db,
            $table: $db.goalVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> goalLogsRefs(
    Expression<bool> Function($$GoalLogsTableFilterComposer f) f,
  ) {
    final $$GoalLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalLogs,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalLogsTableFilterComposer(
            $db: $db,
            $table: $db.goalLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> blackoutDatesRefs(
    Expression<bool> Function($$BlackoutDatesTableFilterComposer f) f,
  ) {
    final $$BlackoutDatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blackoutDates,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlackoutDatesTableFilterComposer(
            $db: $db,
            $table: $db.blackoutDates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cheatDaysRefs(
    Expression<bool> Function($$CheatDaysTableFilterComposer f) f,
  ) {
    final $$CheatDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cheatDays,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheatDaysTableFilterComposer(
            $db: $db,
            $table: $db.cheatDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> statusCachesRefs(
    Expression<bool> Function($$StatusCachesTableFilterComposer f) f,
  ) {
    final $$StatusCachesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.statusCaches,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatusCachesTableFilterComposer(
            $db: $db,
            $table: $db.statusCaches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  Expression<T> goalVersionsRefs<T extends Object>(
    Expression<T> Function($$GoalVersionsTableAnnotationComposer a) f,
  ) {
    final $$GoalVersionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalVersions,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalVersionsTableAnnotationComposer(
            $db: $db,
            $table: $db.goalVersions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> goalLogsRefs<T extends Object>(
    Expression<T> Function($$GoalLogsTableAnnotationComposer a) f,
  ) {
    final $$GoalLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goalLogs,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.goalLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> blackoutDatesRefs<T extends Object>(
    Expression<T> Function($$BlackoutDatesTableAnnotationComposer a) f,
  ) {
    final $$BlackoutDatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.blackoutDates,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BlackoutDatesTableAnnotationComposer(
            $db: $db,
            $table: $db.blackoutDates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cheatDaysRefs<T extends Object>(
    Expression<T> Function($$CheatDaysTableAnnotationComposer a) f,
  ) {
    final $$CheatDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cheatDays,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CheatDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.cheatDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> statusCachesRefs<T extends Object>(
    Expression<T> Function($$StatusCachesTableAnnotationComposer a) f,
  ) {
    final $$StatusCachesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.statusCaches,
      getReferencedColumn: (t) => t.goalId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StatusCachesTableAnnotationComposer(
            $db: $db,
            $table: $db.statusCaches,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalRow,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalRow, $$GoalsTableReferences),
          GoalRow,
          PrefetchHooks Function({
            bool goalVersionsRefs,
            bool goalLogsRefs,
            bool blackoutDatesRefs,
            bool cheatDaysRefs,
            bool statusCachesRefs,
          })
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                name: name,
                description: description,
                category: category,
                archived: archived,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                required String startDate,
                Value<String?> endDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                name: name,
                description: description,
                category: category,
                archived: archived,
                startDate: startDate,
                endDate: endDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$GoalsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                goalVersionsRefs = false,
                goalLogsRefs = false,
                blackoutDatesRefs = false,
                cheatDaysRefs = false,
                statusCachesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (goalVersionsRefs) db.goalVersions,
                    if (goalLogsRefs) db.goalLogs,
                    if (blackoutDatesRefs) db.blackoutDates,
                    if (cheatDaysRefs) db.cheatDays,
                    if (statusCachesRefs) db.statusCaches,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (goalVersionsRefs)
                        await $_getPrefetchedData<
                          GoalRow,
                          $GoalsTable,
                          GoalVersionRow
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._goalVersionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).goalVersionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (goalLogsRefs)
                        await $_getPrefetchedData<
                          GoalRow,
                          $GoalsTable,
                          GoalLogRow
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._goalLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).goalLogsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (blackoutDatesRefs)
                        await $_getPrefetchedData<
                          GoalRow,
                          $GoalsTable,
                          BlackoutDateRow
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._blackoutDatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).blackoutDatesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (cheatDaysRefs)
                        await $_getPrefetchedData<
                          GoalRow,
                          $GoalsTable,
                          CheatDayRow
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._cheatDaysRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).cheatDaysRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (statusCachesRefs)
                        await $_getPrefetchedData<
                          GoalRow,
                          $GoalsTable,
                          StatusCacheRow
                        >(
                          currentTable: table,
                          referencedTable: $$GoalsTableReferences
                              ._statusCachesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$GoalsTableReferences(
                                db,
                                table,
                                p0,
                              ).statusCachesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.goalId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalRow,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalRow, $$GoalsTableReferences),
      GoalRow,
      PrefetchHooks Function({
        bool goalVersionsRefs,
        bool goalLogsRefs,
        bool blackoutDatesRefs,
        bool cheatDaysRefs,
        bool statusCachesRefs,
      })
    >;
typedef $$GoalVersionsTableCreateCompanionBuilder =
    GoalVersionsCompanion Function({
      required String id,
      required String goalId,
      required String versionStartDate,
      required String evaluationPeriod,
      required String eligibleDaysRule,
      required String targetComparison,
      required String targetValue,
      required String trackingType,
      Value<int> cheatDayQuota,
      Value<bool> isPaused,
      Value<int> rowid,
    });
typedef $$GoalVersionsTableUpdateCompanionBuilder =
    GoalVersionsCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<String> versionStartDate,
      Value<String> evaluationPeriod,
      Value<String> eligibleDaysRule,
      Value<String> targetComparison,
      Value<String> targetValue,
      Value<String> trackingType,
      Value<int> cheatDayQuota,
      Value<bool> isPaused,
      Value<int> rowid,
    });

final class $$GoalVersionsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalVersionsTable, GoalVersionRow> {
  $$GoalVersionsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('goal_versions__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalVersionsTableFilterComposer
    extends Composer<_$AppDatabase, $GoalVersionsTable> {
  $$GoalVersionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get versionStartDate => $composableBuilder(
    column: $table.versionStartDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get evaluationPeriod => $composableBuilder(
    column: $table.evaluationPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eligibleDaysRule => $composableBuilder(
    column: $table.eligibleDaysRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetComparison => $composableBuilder(
    column: $table.targetComparison,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get trackingType => $composableBuilder(
    column: $table.trackingType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cheatDayQuota => $composableBuilder(
    column: $table.cheatDayQuota,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPaused => $composableBuilder(
    column: $table.isPaused,
    builder: (column) => ColumnFilters(column),
  );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalVersionsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalVersionsTable> {
  $$GoalVersionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get versionStartDate => $composableBuilder(
    column: $table.versionStartDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get evaluationPeriod => $composableBuilder(
    column: $table.evaluationPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eligibleDaysRule => $composableBuilder(
    column: $table.eligibleDaysRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetComparison => $composableBuilder(
    column: $table.targetComparison,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get trackingType => $composableBuilder(
    column: $table.trackingType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cheatDayQuota => $composableBuilder(
    column: $table.cheatDayQuota,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPaused => $composableBuilder(
    column: $table.isPaused,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalVersionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalVersionsTable> {
  $$GoalVersionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get versionStartDate => $composableBuilder(
    column: $table.versionStartDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get evaluationPeriod => $composableBuilder(
    column: $table.evaluationPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<String> get eligibleDaysRule => $composableBuilder(
    column: $table.eligibleDaysRule,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetComparison => $composableBuilder(
    column: $table.targetComparison,
    builder: (column) => column,
  );

  GeneratedColumn<String> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get trackingType => $composableBuilder(
    column: $table.trackingType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cheatDayQuota => $composableBuilder(
    column: $table.cheatDayQuota,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPaused =>
      $composableBuilder(column: $table.isPaused, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalVersionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalVersionsTable,
          GoalVersionRow,
          $$GoalVersionsTableFilterComposer,
          $$GoalVersionsTableOrderingComposer,
          $$GoalVersionsTableAnnotationComposer,
          $$GoalVersionsTableCreateCompanionBuilder,
          $$GoalVersionsTableUpdateCompanionBuilder,
          (GoalVersionRow, $$GoalVersionsTableReferences),
          GoalVersionRow,
          PrefetchHooks Function({bool goalId})
        > {
  $$GoalVersionsTableTableManager(_$AppDatabase db, $GoalVersionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalVersionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalVersionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalVersionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> versionStartDate = const Value.absent(),
                Value<String> evaluationPeriod = const Value.absent(),
                Value<String> eligibleDaysRule = const Value.absent(),
                Value<String> targetComparison = const Value.absent(),
                Value<String> targetValue = const Value.absent(),
                Value<String> trackingType = const Value.absent(),
                Value<int> cheatDayQuota = const Value.absent(),
                Value<bool> isPaused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalVersionsCompanion(
                id: id,
                goalId: goalId,
                versionStartDate: versionStartDate,
                evaluationPeriod: evaluationPeriod,
                eligibleDaysRule: eligibleDaysRule,
                targetComparison: targetComparison,
                targetValue: targetValue,
                trackingType: trackingType,
                cheatDayQuota: cheatDayQuota,
                isPaused: isPaused,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String versionStartDate,
                required String evaluationPeriod,
                required String eligibleDaysRule,
                required String targetComparison,
                required String targetValue,
                required String trackingType,
                Value<int> cheatDayQuota = const Value.absent(),
                Value<bool> isPaused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalVersionsCompanion.insert(
                id: id,
                goalId: goalId,
                versionStartDate: versionStartDate,
                evaluationPeriod: evaluationPeriod,
                eligibleDaysRule: eligibleDaysRule,
                targetComparison: targetComparison,
                targetValue: targetValue,
                trackingType: trackingType,
                cheatDayQuota: cheatDayQuota,
                isPaused: isPaused,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GoalVersionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
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
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$GoalVersionsTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$GoalVersionsTableReferences
                            ._goalIdTable(db)
                            .id,
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

typedef $$GoalVersionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalVersionsTable,
      GoalVersionRow,
      $$GoalVersionsTableFilterComposer,
      $$GoalVersionsTableOrderingComposer,
      $$GoalVersionsTableAnnotationComposer,
      $$GoalVersionsTableCreateCompanionBuilder,
      $$GoalVersionsTableUpdateCompanionBuilder,
      (GoalVersionRow, $$GoalVersionsTableReferences),
      GoalVersionRow,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$GoalLogsTableCreateCompanionBuilder = GoalLogsCompanion Function({
  required String id,
  required String goalId,
  required String date,
  required String timestamp,
  required double value,
  required bool completed,
  Value<bool> dnfMarked,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$GoalLogsTableUpdateCompanionBuilder = GoalLogsCompanion Function({
  Value<String> id,
  Value<String> goalId,
  Value<String> date,
  Value<String> timestamp,
  Value<double> value,
  Value<bool> completed,
  Value<bool> dnfMarked,
  Value<String?> note,
  Value<int> rowid,
});

final class $$GoalLogsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalLogsTable, GoalLogRow> {
  $$GoalLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('goal_logs__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalLogsTableFilterComposer
    extends Composer<_$AppDatabase, $GoalLogsTable> {
  $$GoalLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get dnfMarked => $composableBuilder(
    column: $table.dnfMarked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalLogsTable> {
  $$GoalLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get dnfMarked => $composableBuilder(
    column: $table.dnfMarked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalLogsTable> {
  $$GoalLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<bool> get dnfMarked =>
      $composableBuilder(column: $table.dnfMarked, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalLogsTable,
          GoalLogRow,
          $$GoalLogsTableFilterComposer,
          $$GoalLogsTableOrderingComposer,
          $$GoalLogsTableAnnotationComposer,
          $$GoalLogsTableCreateCompanionBuilder,
          $$GoalLogsTableUpdateCompanionBuilder,
          (GoalLogRow, $$GoalLogsTableReferences),
          GoalLogRow,
          PrefetchHooks Function({bool goalId})
        > {
  $$GoalLogsTableTableManager(_$AppDatabase db, $GoalLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> timestamp = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<bool> dnfMarked = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalLogsCompanion(
                id: id,
                goalId: goalId,
                date: date,
                timestamp: timestamp,
                value: value,
                completed: completed,
                dnfMarked: dnfMarked,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String date,
                required String timestamp,
                required double value,
                required bool completed,
                Value<bool> dnfMarked = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalLogsCompanion.insert(
                id: id,
                goalId: goalId,
                date: date,
                timestamp: timestamp,
                value: value,
                completed: completed,
                dnfMarked: dnfMarked,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$GoalLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
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
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$GoalLogsTableReferences._goalIdTable(
                          db,
                        ),
                        referencedColumn: $$GoalLogsTableReferences
                            ._goalIdTable(db)
                            .id,
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

typedef $$GoalLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalLogsTable,
      GoalLogRow,
      $$GoalLogsTableFilterComposer,
      $$GoalLogsTableOrderingComposer,
      $$GoalLogsTableAnnotationComposer,
      $$GoalLogsTableCreateCompanionBuilder,
      $$GoalLogsTableUpdateCompanionBuilder,
      (GoalLogRow, $$GoalLogsTableReferences),
      GoalLogRow,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$BlackoutDatesTableCreateCompanionBuilder =
    BlackoutDatesCompanion Function({
      required String id,
      required String goalId,
      required String date,
      Value<String?> reason,
      Value<int> rowid,
    });
typedef $$BlackoutDatesTableUpdateCompanionBuilder =
    BlackoutDatesCompanion Function({
      Value<String> id,
      Value<String> goalId,
      Value<String> date,
      Value<String?> reason,
      Value<int> rowid,
    });

final class $$BlackoutDatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $BlackoutDatesTable, BlackoutDateRow> {
  $$BlackoutDatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('blackout_dates__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BlackoutDatesTableFilterComposer
    extends Composer<_$AppDatabase, $BlackoutDatesTable> {
  $$BlackoutDatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnFilters(column),
  );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BlackoutDatesTableOrderingComposer
    extends Composer<_$AppDatabase, $BlackoutDatesTable> {
  $$BlackoutDatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reason => $composableBuilder(
    column: $table.reason,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BlackoutDatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BlackoutDatesTable> {
  $$BlackoutDatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get reason =>
      $composableBuilder(column: $table.reason, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BlackoutDatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BlackoutDatesTable,
          BlackoutDateRow,
          $$BlackoutDatesTableFilterComposer,
          $$BlackoutDatesTableOrderingComposer,
          $$BlackoutDatesTableAnnotationComposer,
          $$BlackoutDatesTableCreateCompanionBuilder,
          $$BlackoutDatesTableUpdateCompanionBuilder,
          (BlackoutDateRow, $$BlackoutDatesTableReferences),
          BlackoutDateRow,
          PrefetchHooks Function({bool goalId})
        > {
  $$BlackoutDatesTableTableManager(_$AppDatabase db, $BlackoutDatesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BlackoutDatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BlackoutDatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BlackoutDatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlackoutDatesCompanion(
                id: id,
                goalId: goalId,
                date: date,
                reason: reason,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String date,
                Value<String?> reason = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BlackoutDatesCompanion.insert(
                id: id,
                goalId: goalId,
                date: date,
                reason: reason,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BlackoutDatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
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
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$BlackoutDatesTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$BlackoutDatesTableReferences
                            ._goalIdTable(db)
                            .id,
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

typedef $$BlackoutDatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BlackoutDatesTable,
      BlackoutDateRow,
      $$BlackoutDatesTableFilterComposer,
      $$BlackoutDatesTableOrderingComposer,
      $$BlackoutDatesTableAnnotationComposer,
      $$BlackoutDatesTableCreateCompanionBuilder,
      $$BlackoutDatesTableUpdateCompanionBuilder,
      (BlackoutDateRow, $$BlackoutDatesTableReferences),
      BlackoutDateRow,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$CheatDaysTableCreateCompanionBuilder = CheatDaysCompanion Function({
  required String id,
  required String goalId,
  required String date,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$CheatDaysTableUpdateCompanionBuilder = CheatDaysCompanion Function({
  Value<String> id,
  Value<String> goalId,
  Value<String> date,
  Value<String?> note,
  Value<int> rowid,
});

final class $$CheatDaysTableReferences
    extends BaseReferences<_$AppDatabase, $CheatDaysTable, CheatDayRow> {
  $$CheatDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('cheat_days__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CheatDaysTableFilterComposer
    extends Composer<_$AppDatabase, $CheatDaysTable> {
  $$CheatDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheatDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $CheatDaysTable> {
  $$CheatDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheatDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $CheatDaysTable> {
  $$CheatDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CheatDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CheatDaysTable,
          CheatDayRow,
          $$CheatDaysTableFilterComposer,
          $$CheatDaysTableOrderingComposer,
          $$CheatDaysTableAnnotationComposer,
          $$CheatDaysTableCreateCompanionBuilder,
          $$CheatDaysTableUpdateCompanionBuilder,
          (CheatDayRow, $$CheatDaysTableReferences),
          CheatDayRow,
          PrefetchHooks Function({bool goalId})
        > {
  $$CheatDaysTableTableManager(_$AppDatabase db, $CheatDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheatDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheatDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheatDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> goalId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheatDaysCompanion(
                id: id,
                goalId: goalId,
                date: date,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String goalId,
                required String date,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CheatDaysCompanion.insert(
                id: id,
                goalId: goalId,
                date: date,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$CheatDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
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
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$CheatDaysTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$CheatDaysTableReferences
                            ._goalIdTable(db)
                            .id,
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

typedef $$CheatDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CheatDaysTable,
      CheatDayRow,
      $$CheatDaysTableFilterComposer,
      $$CheatDaysTableOrderingComposer,
      $$CheatDaysTableAnnotationComposer,
      $$CheatDaysTableCreateCompanionBuilder,
      $$CheatDaysTableUpdateCompanionBuilder,
      (CheatDayRow, $$CheatDaysTableReferences),
      CheatDayRow,
      PrefetchHooks Function({bool goalId})
    >;
typedef $$StatusCachesTableCreateCompanionBuilder =
    StatusCachesCompanion Function({
      required String goalId,
      required String date,
      required String status,
      Value<double?> currentValue,
      Value<double?> targetValue,
      Value<int> rowid,
    });
typedef $$StatusCachesTableUpdateCompanionBuilder =
    StatusCachesCompanion Function({
      Value<String> goalId,
      Value<String> date,
      Value<String> status,
      Value<double?> currentValue,
      Value<double?> targetValue,
      Value<int> rowid,
    });

final class $$StatusCachesTableReferences
    extends BaseReferences<_$AppDatabase, $StatusCachesTable, StatusCacheRow> {
  $$StatusCachesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $GoalsTable _goalIdTable(_$AppDatabase db) =>
      db.goals.createAlias('status_caches__goal_id__goals__id');

  $$GoalsTableProcessedTableManager get goalId {
    final $_column = $_itemColumn<String>('goal_id')!;

    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_goalIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StatusCachesTableFilterComposer
    extends Composer<_$AppDatabase, $StatusCachesTable> {
  $$StatusCachesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnFilters(column),
  );

  $$GoalsTableFilterComposer get goalId {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StatusCachesTableOrderingComposer
    extends Composer<_$AppDatabase, $StatusCachesTable> {
  $$StatusCachesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => ColumnOrderings(column),
  );

  $$GoalsTableOrderingComposer get goalId {
    final $$GoalsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableOrderingComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StatusCachesTableAnnotationComposer
    extends Composer<_$AppDatabase, $StatusCachesTable> {
  $$StatusCachesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get currentValue => $composableBuilder(
    column: $table.currentValue,
    builder: (column) => column,
  );

  GeneratedColumn<double> get targetValue => $composableBuilder(
    column: $table.targetValue,
    builder: (column) => column,
  );

  $$GoalsTableAnnotationComposer get goalId {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.goalId,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StatusCachesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StatusCachesTable,
          StatusCacheRow,
          $$StatusCachesTableFilterComposer,
          $$StatusCachesTableOrderingComposer,
          $$StatusCachesTableAnnotationComposer,
          $$StatusCachesTableCreateCompanionBuilder,
          $$StatusCachesTableUpdateCompanionBuilder,
          (StatusCacheRow, $$StatusCachesTableReferences),
          StatusCacheRow,
          PrefetchHooks Function({bool goalId})
        > {
  $$StatusCachesTableTableManager(_$AppDatabase db, $StatusCachesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StatusCachesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StatusCachesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StatusCachesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> goalId = const Value.absent(),
                Value<String> date = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> currentValue = const Value.absent(),
                Value<double?> targetValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StatusCachesCompanion(
                goalId: goalId,
                date: date,
                status: status,
                currentValue: currentValue,
                targetValue: targetValue,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String goalId,
                required String date,
                required String status,
                Value<double?> currentValue = const Value.absent(),
                Value<double?> targetValue = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StatusCachesCompanion.insert(
                goalId: goalId,
                date: date,
                status: status,
                currentValue: currentValue,
                targetValue: targetValue,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StatusCachesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({goalId = false}) {
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
                    if (goalId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.goalId,
                        referencedTable: $$StatusCachesTableReferences
                            ._goalIdTable(db),
                        referencedColumn: $$StatusCachesTableReferences
                            ._goalIdTable(db)
                            .id,
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

typedef $$StatusCachesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StatusCachesTable,
      StatusCacheRow,
      $$StatusCachesTableFilterComposer,
      $$StatusCachesTableOrderingComposer,
      $$StatusCachesTableAnnotationComposer,
      $$StatusCachesTableCreateCompanionBuilder,
      $$StatusCachesTableUpdateCompanionBuilder,
      (StatusCacheRow, $$StatusCachesTableReferences),
      StatusCacheRow,
      PrefetchHooks Function({bool goalId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$GoalVersionsTableTableManager get goalVersions =>
      $$GoalVersionsTableTableManager(_db, _db.goalVersions);
  $$GoalLogsTableTableManager get goalLogs =>
      $$GoalLogsTableTableManager(_db, _db.goalLogs);
  $$BlackoutDatesTableTableManager get blackoutDates =>
      $$BlackoutDatesTableTableManager(_db, _db.blackoutDates);
  $$CheatDaysTableTableManager get cheatDays =>
      $$CheatDaysTableTableManager(_db, _db.cheatDays);
  $$StatusCachesTableTableManager get statusCaches =>
      $$StatusCachesTableTableManager(_db, _db.statusCaches);
}
