// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(statsService)
final statsServiceProvider = StatsServiceProvider._();

final class StatsServiceProvider
    extends $FunctionalProvider<StatsService, StatsService, StatsService>
    with $Provider<StatsService> {
  StatsServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statsServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statsServiceHash();

  @$internal
  @override
  $ProviderElement<StatsService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StatsService create(Ref ref) {
    return statsService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatsService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatsService>(value),
    );
  }
}

String _$statsServiceHash() => r'ec2b79be44ec66c1d671ffe3dcdfbbb2970ee153';

@ProviderFor(todayProgress)
final todayProgressProvider = TodayProgressProvider._();

final class TodayProgressProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GoalStatus>>,
          List<GoalStatus>,
          FutureOr<List<GoalStatus>>
        >
    with $FutureModifier<List<GoalStatus>>, $FutureProvider<List<GoalStatus>> {
  TodayProgressProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayProgressProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayProgressHash();

  @$internal
  @override
  $FutureProviderElement<List<GoalStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GoalStatus>> create(Ref ref) {
    return todayProgress(ref);
  }
}

String _$todayProgressHash() => r'95d053629ca1029ef1ea3aaea9f2b3eaebb26a89';

@ProviderFor(weekRollup)
final weekRollupProvider = WeekRollupProvider._();

final class WeekRollupProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GoalStatus>>,
          List<GoalStatus>,
          FutureOr<List<GoalStatus>>
        >
    with $FutureModifier<List<GoalStatus>>, $FutureProvider<List<GoalStatus>> {
  WeekRollupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekRollupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekRollupHash();

  @$internal
  @override
  $FutureProviderElement<List<GoalStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GoalStatus>> create(Ref ref) {
    return weekRollup(ref);
  }
}

String _$weekRollupHash() => r'dffb5e184d37a0f55bc2df12752e3bb8e207e9ed';

@ProviderFor(monthRollup)
final monthRollupProvider = MonthRollupProvider._();

final class MonthRollupProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GoalStatus>>,
          List<GoalStatus>,
          FutureOr<List<GoalStatus>>
        >
    with $FutureModifier<List<GoalStatus>>, $FutureProvider<List<GoalStatus>> {
  MonthRollupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'monthRollupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$monthRollupHash();

  @$internal
  @override
  $FutureProviderElement<List<GoalStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GoalStatus>> create(Ref ref) {
    return monthRollup(ref);
  }
}

String _$monthRollupHash() => r'e196bfc24b63f94c2440e523d4b1754488b68986';

@ProviderFor(currentStreak)
final currentStreakProvider = CurrentStreakFamily._();

final class CurrentStreakProvider
    extends $FunctionalProvider<AsyncValue<int?>, int?, FutureOr<int?>>
    with $FutureModifier<int?>, $FutureProvider<int?> {
  CurrentStreakProvider._({
    required CurrentStreakFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'currentStreakProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentStreakHash();

  @override
  String toString() {
    return r'currentStreakProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int?> create(Ref ref) {
    final argument = this.argument as String;
    return currentStreak(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentStreakProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentStreakHash() => r'a1f9df1e0b53d0030d53fd9f4e52c7b9a2187824';

final class CurrentStreakFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int?>, String> {
  CurrentStreakFamily._()
    : super(
        retry: null,
        name: r'currentStreakProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrentStreakProvider call(String goalId) =>
      CurrentStreakProvider._(argument: goalId, from: this);

  @override
  String toString() => r'currentStreakProvider';
}

/// Story 3.2 AC 1: Goal Detail's bundled current/longest streak + completion
/// percentage — always the same [StatsService.goalStats] call, never a
/// second computation (AD-8).

@ProviderFor(goalStats)
final goalStatsProvider = GoalStatsFamily._();

/// Story 3.2 AC 1: Goal Detail's bundled current/longest streak + completion
/// percentage — always the same [StatsService.goalStats] call, never a
/// second computation (AD-8).

final class GoalStatsProvider
    extends
        $FunctionalProvider<
          AsyncValue<GoalStats>,
          GoalStats,
          FutureOr<GoalStats>
        >
    with $FutureModifier<GoalStats>, $FutureProvider<GoalStats> {
  /// Story 3.2 AC 1: Goal Detail's bundled current/longest streak + completion
  /// percentage — always the same [StatsService.goalStats] call, never a
  /// second computation (AD-8).
  GoalStatsProvider._({
    required GoalStatsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'goalStatsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goalStatsHash();

  @override
  String toString() {
    return r'goalStatsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GoalStats> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GoalStats> create(Ref ref) {
    final argument = this.argument as String;
    return goalStats(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GoalStatsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalStatsHash() => r'0efbc50c347e18c25013d1ef29fd910b496b8d0e';

/// Story 3.2 AC 1: Goal Detail's bundled current/longest streak + completion
/// percentage — always the same [StatsService.goalStats] call, never a
/// second computation (AD-8).

final class GoalStatsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GoalStats>, String> {
  GoalStatsFamily._()
    : super(
        retry: null,
        name: r'goalStatsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Story 3.2 AC 1: Goal Detail's bundled current/longest streak + completion
  /// percentage — always the same [StatsService.goalStats] call, never a
  /// second computation (AD-8).

  GoalStatsProvider call(String goalId) =>
      GoalStatsProvider._(argument: goalId, from: this);

  @override
  String toString() => r'goalStatsProvider';
}

/// Story 3.2 Subtask 2.1: the Goal Detail historical calendar's data source.

@ProviderFor(historicalStatuses)
final historicalStatusesProvider = HistoricalStatusesFamily._();

/// Story 3.2 Subtask 2.1: the Goal Detail historical calendar's data source.

final class HistoricalStatusesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<DayStatus>>,
          List<DayStatus>,
          FutureOr<List<DayStatus>>
        >
    with $FutureModifier<List<DayStatus>>, $FutureProvider<List<DayStatus>> {
  /// Story 3.2 Subtask 2.1: the Goal Detail historical calendar's data source.
  HistoricalStatusesProvider._({
    required HistoricalStatusesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'historicalStatusesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$historicalStatusesHash();

  @override
  String toString() {
    return r'historicalStatusesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<DayStatus>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<DayStatus>> create(Ref ref) {
    final argument = this.argument as String;
    return historicalStatuses(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HistoricalStatusesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$historicalStatusesHash() =>
    r'443e52f6efedad68925ec7c0a6c1ddc43a108a7d';

/// Story 3.2 Subtask 2.1: the Goal Detail historical calendar's data source.

final class HistoricalStatusesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<DayStatus>>, String> {
  HistoricalStatusesFamily._()
    : super(
        retry: null,
        name: r'historicalStatusesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Story 3.2 Subtask 2.1: the Goal Detail historical calendar's data source.

  HistoricalStatusesProvider call(String goalId) =>
      HistoricalStatusesProvider._(argument: goalId, from: this);

  @override
  String toString() => r'historicalStatusesProvider';
}
