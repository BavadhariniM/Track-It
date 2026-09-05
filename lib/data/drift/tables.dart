import 'package:drift/drift.dart';

/// Row data classes are named `*Row` (via `@DataClassName`) to avoid
/// colliding with the same-named domain entities in `lib/domain/entities/`
/// — Drift rows and domain entities are deliberately distinct types;
/// `data/repositories/` converts between them (AD-1).

@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  TextColumn get startDate => text()();
  TextColumn get endDate => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalVersionRow')
class GoalVersions extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get versionStartDate => text()();
  TextColumn get evaluationPeriod => text()();
  TextColumn get eligibleDaysRule => text()();
  TextColumn get targetComparison => text()();
  TextColumn get targetValue => text()();
  TextColumn get trackingType => text()();
  IntColumn get cheatDayQuota => integer().withDefault(const Constant(0))();
  BoolColumn get isPaused => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalLogRow')
class GoalLogs extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get date => text()();
  TextColumn get timestamp => text()();
  RealColumn get value => real()();
  BoolColumn get completed => boolean()();
  BoolColumn get dnfMarked => boolean().withDefault(const Constant(false))();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// The only new table Story 1.6 adds — `CHEAT_DAY`'s table arrives with
/// Epic 2 Story 2.4, never before.
@DataClassName('BlackoutDateRow')
class BlackoutDates extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get date => text()();
  TextColumn get reason => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Story 2.4: the `CHEAT_DAY` half of the sheet Story 1.6 introduced as
/// Blackout-only — deferred until this story per the ERD's "no table is
/// created before the story that needs it" sequencing.
@DataClassName('CheatDayRow')
class CheatDays extends Table {
  TextColumn get id => text()();
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get date => text()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Story 3.1 (AD-7): the read-optimization status cache. Columns match bare
/// `DayStatus` exactly — no additional denormalized rollup fields (AD-7
/// mandates "bare `DayStatus` only"). Every row is provably re-derivable by
/// calling `evaluate()` fresh for `(goalId, date)`, so this table is never a
/// second source of truth — only a `CacheWriter`-maintained read
/// optimization over what `evaluate()` would already compute.
@DataClassName('StatusCacheRow')
class StatusCaches extends Table {
  TextColumn get goalId => text().references(Goals, #id)();
  TextColumn get date => text()();
  TextColumn get status => text()();
  RealColumn get currentValue => real().nullable()();
  RealColumn get targetValue => real().nullable()();

  @override
  Set<Column> get primaryKey => {goalId, date};
}
