// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_data_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The reactive data `evaluate()` needs. Day View watches [allGoals], and
/// for each goal watches [goalVersions]/[goalLogs] to call the domain's
/// pure `evaluate()` function itself — this story does not introduce a
/// second evaluation path, only the data plumbing evaluate() consumes.

@ProviderFor(allGoals)
final allGoalsProvider = AllGoalsProvider._();

/// The reactive data `evaluate()` needs. Day View watches [allGoals], and
/// for each goal watches [goalVersions]/[goalLogs] to call the domain's
/// pure `evaluate()` function itself — this story does not introduce a
/// second evaluation path, only the data plumbing evaluate() consumes.

final class AllGoalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Goal>>,
          List<Goal>,
          Stream<List<Goal>>
        >
    with $FutureModifier<List<Goal>>, $StreamProvider<List<Goal>> {
  /// The reactive data `evaluate()` needs. Day View watches [allGoals], and
  /// for each goal watches [goalVersions]/[goalLogs] to call the domain's
  /// pure `evaluate()` function itself — this story does not introduce a
  /// second evaluation path, only the data plumbing evaluate() consumes.
  AllGoalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allGoalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allGoalsHash();

  @$internal
  @override
  $StreamProviderElement<List<Goal>> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<List<Goal>> create(Ref ref) {
    return allGoals(ref);
  }
}

String _$allGoalsHash() => r'43bcafbcfd6a88b2cfd8b6ee5a6762ef064dc244';

/// Story 3.5 Subtask 2.1/2.3: [allGoals] scoped by the Calendar's current
/// [GoalFilter] — the exact list of goals the Day/Week/Month calendar's
/// existing `evaluate()` loop iterates over. Filtering only changes which
/// goals are in this list; it is never a second read path, never a cache
/// lookup (AD-7 stays untouched), and [allGoals]'s own loading/error states
/// pass straight through.

@ProviderFor(filteredGoals)
final filteredGoalsProvider = FilteredGoalsProvider._();

/// Story 3.5 Subtask 2.1/2.3: [allGoals] scoped by the Calendar's current
/// [GoalFilter] — the exact list of goals the Day/Week/Month calendar's
/// existing `evaluate()` loop iterates over. Filtering only changes which
/// goals are in this list; it is never a second read path, never a cache
/// lookup (AD-7 stays untouched), and [allGoals]'s own loading/error states
/// pass straight through.

final class FilteredGoalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Goal>>,
          AsyncValue<List<Goal>>,
          AsyncValue<List<Goal>>
        >
    with $Provider<AsyncValue<List<Goal>>> {
  /// Story 3.5 Subtask 2.1/2.3: [allGoals] scoped by the Calendar's current
  /// [GoalFilter] — the exact list of goals the Day/Week/Month calendar's
  /// existing `evaluate()` loop iterates over. Filtering only changes which
  /// goals are in this list; it is never a second read path, never a cache
  /// lookup (AD-7 stays untouched), and [allGoals]'s own loading/error states
  /// pass straight through.
  FilteredGoalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filteredGoalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filteredGoalsHash();

  @$internal
  @override
  $ProviderElement<AsyncValue<List<Goal>>> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AsyncValue<List<Goal>> create(Ref ref) {
    return filteredGoals(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<List<Goal>> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<List<Goal>>>(value),
    );
  }
}

String _$filteredGoalsHash() => r'cc8e09b2ad3bbd75bcaa1527b2828c2ea2470ade';

@ProviderFor(goalVersions)
final goalVersionsProvider = GoalVersionsFamily._();

final class GoalVersionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GoalVersion>>,
          List<GoalVersion>,
          Stream<List<GoalVersion>>
        >
    with
        $FutureModifier<List<GoalVersion>>,
        $StreamProvider<List<GoalVersion>> {
  GoalVersionsProvider._({
    required GoalVersionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'goalVersionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goalVersionsHash();

  @override
  String toString() {
    return r'goalVersionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GoalVersion>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GoalVersion>> create(Ref ref) {
    final argument = this.argument as String;
    return goalVersions(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GoalVersionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalVersionsHash() => r'b2e140bf99ac0c34116b041da1da1ad5e9956bad';

final class GoalVersionsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GoalVersion>>, String> {
  GoalVersionsFamily._()
    : super(
        retry: null,
        name: r'goalVersionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GoalVersionsProvider call(String goalId) =>
      GoalVersionsProvider._(argument: goalId, from: this);

  @override
  String toString() => r'goalVersionsProvider';
}

@ProviderFor(goalLogs)
final goalLogsProvider = GoalLogsFamily._();

final class GoalLogsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GoalLog>>,
          List<GoalLog>,
          Stream<List<GoalLog>>
        >
    with $FutureModifier<List<GoalLog>>, $StreamProvider<List<GoalLog>> {
  GoalLogsProvider._({
    required GoalLogsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'goalLogsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goalLogsHash();

  @override
  String toString() {
    return r'goalLogsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<GoalLog>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GoalLog>> create(Ref ref) {
    final argument = this.argument as String;
    return goalLogs(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GoalLogsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goalLogsHash() => r'afd244148a7ad68eb3e594f3018cca49b45d5b1d';

final class GoalLogsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<GoalLog>>, String> {
  GoalLogsFamily._()
    : super(
        retry: null,
        name: r'goalLogsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GoalLogsProvider call(String goalId) =>
      GoalLogsProvider._(argument: goalId, from: this);

  @override
  String toString() => r'goalLogsProvider';
}

@ProviderFor(blackoutDates)
final blackoutDatesProvider = BlackoutDatesFamily._();

final class BlackoutDatesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BlackoutDate>>,
          List<BlackoutDate>,
          Stream<List<BlackoutDate>>
        >
    with
        $FutureModifier<List<BlackoutDate>>,
        $StreamProvider<List<BlackoutDate>> {
  BlackoutDatesProvider._({
    required BlackoutDatesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'blackoutDatesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$blackoutDatesHash();

  @override
  String toString() {
    return r'blackoutDatesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<BlackoutDate>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BlackoutDate>> create(Ref ref) {
    final argument = this.argument as String;
    return blackoutDates(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BlackoutDatesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$blackoutDatesHash() => r'd6b42efa66e1f5e36f911e441a9d3b36a8d07b38';

final class BlackoutDatesFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<BlackoutDate>>, String> {
  BlackoutDatesFamily._()
    : super(
        retry: null,
        name: r'blackoutDatesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BlackoutDatesProvider call(String goalId) =>
      BlackoutDatesProvider._(argument: goalId, from: this);

  @override
  String toString() => r'blackoutDatesProvider';
}

@ProviderFor(cheatDays)
final cheatDaysProvider = CheatDaysFamily._();

final class CheatDaysProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CheatDay>>,
          List<CheatDay>,
          Stream<List<CheatDay>>
        >
    with $FutureModifier<List<CheatDay>>, $StreamProvider<List<CheatDay>> {
  CheatDaysProvider._({
    required CheatDaysFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'cheatDaysProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$cheatDaysHash();

  @override
  String toString() {
    return r'cheatDaysProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<CheatDay>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<CheatDay>> create(Ref ref) {
    final argument = this.argument as String;
    return cheatDays(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CheatDaysProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$cheatDaysHash() => r'd52c028749a000cb637148c3c3a62aae842475e8';

final class CheatDaysFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<CheatDay>>, String> {
  CheatDaysFamily._()
    : super(
        retry: null,
        name: r'cheatDaysProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CheatDaysProvider call(String goalId) =>
      CheatDaysProvider._(argument: goalId, from: this);

  @override
  String toString() => r'cheatDaysProvider';
}
