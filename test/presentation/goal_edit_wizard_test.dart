import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/goal.dart';
import 'package:tracker/domain/entities/goal_log.dart';
import 'package:tracker/domain/entities/goal_version.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/date_format.dart';
import 'package:tracker/presentation/providers/goal_wizard_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/screens/goal_detail_screen.dart';

import '../domain/services/fakes.dart';

/// Story 2.1 Subtask 5.5: widget coverage for the edit wizard's pre-fill
/// (Task 4.3) and the `versionLocked` error path (Task 4.4) — the
/// presentation-layer behavior not already exercised by
/// `test/domain/services/goal_service_test.dart`'s exhaustive collision-
/// algorithm coverage (Subtasks 5.1-5.4).
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  late InMemoryStore store;
  late Goal goal;
  late GoalVersion version;

  Widget buildApp() {
    return ProviderScope(
      overrides: [
        goalRepositoryProvider.overrideWithValue(InMemoryGoalRepository(store)),
        goalVersionRepositoryProvider.overrideWithValue(
          InMemoryGoalVersionRepository(store),
        ),
        goalLogRepositoryProvider.overrideWithValue(
          InMemoryGoalLogRepository(store),
        ),
        blackoutDateRepositoryProvider.overrideWithValue(
          InMemoryBlackoutDateRepository(store),
        ),
        cheatDayRepositoryProvider.overrideWithValue(
          InMemoryCheatDayRepository(store),
        ),
        transactionRunnerProvider.overrideWithValue(
          SnapshotTransactionRunner(store),
        ),
        statusCacheRepositoryProvider.overrideWithValue(
          InMemoryStatusCacheRepository(store),
        ),
      ],
      child: MaterialApp(home: GoalDetailScreen(goal: goal)),
    );
  }

  setUp(() {
    store = InMemoryStore();
    goal = const Goal(
      id: 'goal-1',
      name: 'Run',
      archived: false,
      startDate: '2026-01-01',
    );
    // Dated exactly "today" so the wizard's default effective date (Task
    // 4.3: "default: today") lines up with AD-6's amend-in-place branch —
    // the same-day-edit case this story's Dev Notes calls the crux of the
    // collision algorithm.
    version = GoalVersion(
      id: 'version-1',
      goalId: goal.id,
      versionStartDate: formatDateOnly(_today()),
      evaluationPeriod: EvaluationPeriod.weekly,
      eligibleDaysRule: EligibleDaysRule.workdays,
      targetComparison: TargetComparison.atLeast,
      targetValue: '3',
      trackingType: TrackingType.counter,
    );
    store.goals.add(goal);
    store.versions.add(version);
  });

  Future<void> openEditWizard(WidgetTester tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('goal-detail-edit-button')));
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('wizard-next-button')));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'edit wizard pre-fills every step from the current Version and amends '
    'it in place on Save',
    (tester) async {
      await openEditWizard(tester);

      // Name step: pre-filled from the Goal, but read-only — Story 2.1's
      // scope is schedule/target only (AC 1), and `editGoalVersion` has no
      // way to persist a name change.
      final nameField = tester.widget<TextField>(
        find.byKey(const Key('wizard-name-field')),
      );
      expect(nameField.controller!.text, 'Run');
      expect(nameField.enabled, isFalse);
      await next(tester); // -> Tracking Type

      expect(
        tester
            .widget<SegmentedButton<String>>(
              find.byKey(const Key('wizard-tracking-type-selector')),
            )
            .selected,
        {TrackingType.counter},
      );
      await next(tester); // -> Schedule

      expect(
        tester
            .widget<DropdownButton<String>>(
              find.byKey(const Key('wizard-evaluation-period-dropdown')),
            )
            .value,
        EvaluationPeriod.weekly,
      );
      await next(tester); // -> Target

      expect(
        tester
            .widget<SegmentedButton<String>>(
              find.byKey(const Key('wizard-target-comparison-selector')),
            )
            .selected,
        {TargetComparison.atLeast},
      );
      expect(
        tester
            .widget<TextField>(
              find.byKey(const Key('wizard-target-value-field')),
            )
            .controller!
            .text,
        '3',
      );

      // Change the target value so Save's effect is observable.
      await tester.enterText(
        find.byKey(const Key('wizard-target-value-field')),
        '5',
      );
      await tester.pumpAndSettle();
      await next(tester); // -> Dates

      // Task 4.3: an effective-date field replaces Start/End date in edit
      // mode, defaulting to today.
      expect(
        find.byKey(const Key('wizard-effective-date-tile')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('wizard-start-date-tile')), findsNothing);
      await next(tester); // -> Reminders
      await next(tester); // -> Review

      await tester.tap(find.byKey(const Key('wizard-save-button')));
      await tester.pumpAndSettle();

      // Amended in place (AD-6): still exactly one Version row, same id,
      // updated field value.
      expect(store.versions, hasLength(1));
      expect(store.versions.single.id, 'version-1');
      expect(store.versions.single.targetValue, '5');
    },
  );

  testWidgets(
    'a versionLocked rejection shows the specific message on the Dates '
    'step and disables Save until a later effective date is chosen',
    (tester) async {
      // A GoalLog on the version's own start date locks a same-day edit
      // (AC 4) — the wizard's default effective date is today, which
      // equals `version.versionStartDate` from setUp.
      store.logs.add(
        GoalLog(
          id: 'log-1',
          goalId: goal.id,
          date: formatDateOnly(_today()),
          timestamp: DateTime.now().toIso8601String(),
          value: 1,
          completed: true,
        ),
      );

      await openEditWizard(tester);
      for (var i = 0; i < 6; i++) {
        await next(tester);
      }

      await tester.tap(find.byKey(const Key('wizard-save-button')));
      await tester.pumpAndSettle();

      // Task 4.4: rejected, kept open on the Dates step with the specific
      // UX-DR19 copy — never a generic failure message.
      expect(
        find.byKey(const Key('wizard-version-locked-message')),
        findsOneWidget,
      );
      expect(
        find.textContaining('choose a later effective date'),
        findsOneWidget,
      );

      // Back always stays enabled (Story 1.9 invariant) — Next is what
      // must be disabled until the date advances.
      expect(
        tester
            .widget<OutlinedButton>(find.byKey(const Key('wizard-back-button')))
            .onPressed,
        isNotNull,
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byKey(const Key('wizard-effective-date-tile'))),
      );
      expect(
        container.read(goalWizardProvider).effectiveDateClearsLock,
        isFalse,
      );

      // Picking a later date clears the rejection and re-enables Save.
      container
          .read(goalWizardProvider.notifier)
          .setStartDate(_today().add(const Duration(days: 1)));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('wizard-version-locked-message')),
        findsNothing,
      );
      expect(
        container.read(goalWizardProvider).effectiveDateClearsLock,
        isTrue,
      );
    },
  );
}
