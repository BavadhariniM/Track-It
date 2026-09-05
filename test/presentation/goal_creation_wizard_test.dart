import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/day_status.dart';
import 'package:tracker/domain/entities/eligible_days_rule.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/evaluate.dart';
import 'package:tracker/presentation/components/primary_button.dart';
import 'package:tracker/presentation/components/wizard/review_sentence.dart';
import 'package:tracker/presentation/providers/goal_wizard_provider.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/screens/day_view.dart';

import '../domain/services/fakes.dart';

/// Story 1.9's Task 9 (Testing) suite — one dedicated file per subtask
/// group so each is independently traceable back to the story:
///
/// - 9.1: full linear flow for 2-3 of Story 1.7's 13 worked-example
///   patterns, confirming Save produces a correctly-evaluable goal.
/// - 9.2: Next-disabled-until-valid, walked through all 7 steps.
/// - 9.3: Back-always-enabled + re-validation-after-editing-an-earlier-step
///   (AC #5's Tracking-Type-change-invalidates-Target-step scenario).
/// - 9.4: the UX-DR16 Streak-clarification banner actually renders for
///   both contrasted patterns, at both the Schedule and Target steps.
/// - 9.5: the Review step's plain-language sentence for varied
///   configurations (`review_sentence.dart`'s pure composition function).
/// `evaluate()`'s cursor arithmetic works in pure calendar dates (midnight);
/// `DateTime.now()` carries a time-of-day that makes "today" compare as
/// already-past against a midnight cursor for the same date, so every
/// `evaluate()` call in this file uses a truncated date — matching how
/// `GoalWizard._today()` itself truncates the wizard's default start date.
DateTime _today() {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
}

void main() {
  late InMemoryStore store;

  Widget buildApp(DateTime date) {
    store = InMemoryStore();
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
      child: MaterialApp(home: DayViewScreen(date: date)),
    );
  }

  Future<void> openWizard(WidgetTester tester, DateTime date) async {
    await tester.pumpWidget(buildApp(date));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Create Goal'));
    await tester.pumpAndSettle();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('wizard-next-button')));
    await tester.pumpAndSettle();
  }

  Future<void> enterName(WidgetTester tester, String name) async {
    await tester.enterText(find.byKey(const Key('wizard-name-field')), name);
    await tester.pumpAndSettle();
  }

  Future<void> selectDropdownValue(
    WidgetTester tester,
    Key dropdownKey,
    String label,
  ) async {
    await tester.tap(find.byKey(dropdownKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  bool nextEnabled(WidgetTester tester) =>
      tester
          .widget<PrimaryButton>(find.byKey(const Key('wizard-next-button')))
          .onPressed !=
      null;

  bool backEnabled(WidgetTester tester) =>
      tester
          .widget<OutlinedButton>(find.byKey(const Key('wizard-back-button')))
          .onPressed !=
      null;

  group('9.1: full flow for worked-example patterns (Story 1.7)', () {
    testWidgets(
      'Pattern 1 — Meditate daily: Boolean/Daily/every day is a fixed '
      'Exactly-1 rule with no comparison/value to pick',
      (tester) async {
        final today = _today();
        await openWizard(tester, today);

        await enterName(tester, 'Meditate');
        await next(tester); // -> Tracking Type

        await tester.tap(find.text('Done / not done'));
        await tester.pumpAndSettle();
        await next(tester); // -> Schedule (Daily + every-day are defaults)

        await next(tester); // -> Target
        expect(
          find.byKey(const Key('wizard-fixed-boolean-daily-note')),
          findsOneWidget,
        );

        await next(tester); // -> Dates
        await next(tester); // -> Reminders
        await next(tester); // -> Review

        expect(find.textContaining('Done each eligible day'), findsOneWidget);

        await tester.tap(find.byKey(const Key('wizard-save-button')));
        await tester.pumpAndSettle();

        expect(store.goals, hasLength(1));
        final version = store.versions.single;
        expect(version.trackingType, TrackingType.boolean);
        expect(version.evaluationPeriod, EvaluationPeriod.daily);
        expect(version.targetComparison, TargetComparison.exactly);
        expect(version.targetValue, '1');
        expect(version.eligibleDaysRule, EligibleDaysRule.everyDay);

        final status = evaluate(
          goal: store.goals.single,
          versions: store.versions,
          logs: const [],
          date: today,
        );
        expect(status.status, DayStatusValue.pending);
      },
    );

    testWidgets('Pattern 11 — At least 3 days in the work week: '
        'Boolean/Weekly/Workdays/At least 3', (tester) async {
      final today = _today();
      await openWizard(tester, today);

      await enterName(tester, 'Gym');
      await next(tester);

      await tester.tap(find.text('Done / not done'));
      await tester.pumpAndSettle();
      await next(tester);

      await selectDropdownValue(
        tester,
        const Key('wizard-evaluation-period-dropdown'),
        'Weekly',
      );
      await tester.tap(find.text('Workdays'));
      await tester.pumpAndSettle();
      await next(tester);

      await tester.tap(find.text('At least'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('wizard-target-value-field')),
        '3',
      );
      await tester.pumpAndSettle();
      await next(tester); // -> Dates

      await next(tester); // -> Reminders
      await next(tester); // -> Review

      expect(
        find.textContaining('Done at least 3 times a week, workdays only'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('wizard-save-button')));
      await tester.pumpAndSettle();

      final version = store.versions.single;
      expect(version.trackingType, TrackingType.boolean);
      expect(version.evaluationPeriod, EvaluationPeriod.weekly);
      expect(version.targetComparison, TargetComparison.atLeast);
      expect(version.targetValue, '3');
      expect(version.eligibleDaysRule, EligibleDaysRule.workdays);
    });

    testWidgets('Pattern 9 — Workout 10x in any rolling 14 days: '
        'Counter/Rolling-window(14)/At least 10', (tester) async {
      final today = _today();
      await openWizard(tester, today);

      await enterName(tester, 'Workout');
      await next(tester);

      await tester.tap(find.text('Counter'));
      await tester.pumpAndSettle();
      await next(tester);

      await selectDropdownValue(
        tester,
        const Key('wizard-evaluation-period-dropdown'),
        'Rolling window (N days)',
      );
      await tester.enterText(
        find.byKey(const Key('wizard-rolling-window-days-field')),
        '14',
      );
      await tester.pumpAndSettle();
      await next(tester);

      await tester.tap(find.text('At least'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('wizard-target-value-field')),
        '10',
      );
      await tester.pumpAndSettle();
      await next(tester); // -> Dates

      await next(tester); // -> Reminders
      await next(tester); // -> Review

      await tester.tap(find.byKey(const Key('wizard-save-button')));
      await tester.pumpAndSettle();

      final version = store.versions.single;
      expect(version.trackingType, TrackingType.counter);
      expect(version.evaluationPeriod, EvaluationPeriod.rollingWindow(14));
      expect(version.targetComparison, TargetComparison.atLeast);
      expect(version.targetValue, '10');

      final status = evaluate(
        goal: store.goals.single,
        versions: store.versions,
        logs: const [],
        date: today,
      );
      expect(status.status, DayStatusValue.pending);
    });
  });

  group('9.2: Next stays disabled until each step validates', () {
    testWidgets('walking all 7 steps in order', (tester) async {
      final today = _today();
      await openWizard(tester, today);

      // Step 1: Name — empty name disables Next.
      expect(nextEnabled(tester), isFalse);
      await enterName(tester, 'Read');
      expect(nextEnabled(tester), isTrue);
      await next(tester);

      // Step 2: Tracking Type — no selection disables Next. Pick Counter
      // so the later Target step isn't the Boolean/Daily fixed case.
      expect(nextEnabled(tester), isFalse);
      await tester.tap(find.text('Counter'));
      await tester.pumpAndSettle();
      expect(nextEnabled(tester), isTrue);
      await next(tester);

      // Step 3: Schedule — valid by default (every-day, Daily). Switching
      // to a Rolling Window with N < 1 must disable Next again.
      expect(nextEnabled(tester), isTrue);
      await selectDropdownValue(
        tester,
        const Key('wizard-evaluation-period-dropdown'),
        'Rolling window (N days)',
      );
      await tester.enterText(
        find.byKey(const Key('wizard-rolling-window-days-field')),
        '0',
      );
      await tester.pumpAndSettle();
      expect(nextEnabled(tester), isFalse);
      await tester.enterText(
        find.byKey(const Key('wizard-rolling-window-days-field')),
        '5',
      );
      await tester.pumpAndSettle();
      expect(nextEnabled(tester), isTrue);
      await next(tester);

      // Step 4: Target — Counter tracking type needs both a comparison and
      // a value; neither alone is enough.
      expect(nextEnabled(tester), isFalse);
      await tester.tap(find.text('At least'));
      await tester.pumpAndSettle();
      expect(nextEnabled(tester), isFalse);
      await tester.enterText(
        find.byKey(const Key('wizard-target-value-field')),
        '5',
      );
      await tester.pumpAndSettle();
      expect(nextEnabled(tester), isTrue);
      await next(tester);

      // Step 5: Dates — valid by default (start date only, no end date).
      expect(nextEnabled(tester), isTrue);
      await next(tester);

      // Step 6: Reminders — trivially always valid.
      expect(nextEnabled(tester), isTrue);
      await next(tester);

      // Step 7: Review — no Next slot; Save reflects reviewStepValid.
      expect(find.byKey(const Key('wizard-next-button')), findsNothing);
      expect(
        tester
            .widget<PrimaryButton>(find.byKey(const Key('wizard-save-button')))
            .onPressed,
        isNotNull,
      );
    });
  });

  group('9.3: Back is always enabled; editing an earlier step re-validates '
      'later ones (AC #5)', () {
    testWidgets(
      'switching Tracking Type from Counter back to Boolean clears the '
      'stale Counter target and the Target step becomes the fixed case',
      (tester) async {
        final today = _today();
        await openWizard(tester, today);
        expect(backEnabled(tester), isTrue); // step 0 — exits, but enabled

        await enterName(tester, 'Read');
        await next(tester);
        expect(backEnabled(tester), isTrue);

        await tester.tap(find.text('Counter'));
        await tester.pumpAndSettle();
        await next(tester); // Schedule
        expect(backEnabled(tester), isTrue);
        await next(tester); // Target (default Daily + Counter, not fixed)

        await tester.tap(find.text('At least'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('wizard-target-value-field')),
          '5',
        );
        await tester.pumpAndSettle();
        expect(nextEnabled(tester), isTrue);
        expect(backEnabled(tester), isTrue);

        // Back to Schedule, then back to Tracking Type.
        await tester.tap(find.byKey(const Key('wizard-back-button')));
        await tester.pumpAndSettle();
        expect(backEnabled(tester), isTrue);
        await tester.tap(find.byKey(const Key('wizard-back-button')));
        await tester.pumpAndSettle();
        expect(backEnabled(tester), isTrue);

        // Switch to Boolean — the Target step's Counter comparison/value
        // must not silently survive this change (setTrackingType clears
        // them, per goal_wizard_provider.dart).
        await tester.tap(find.text('Done / not done'));
        await tester.pumpAndSettle();

        await next(tester); // Schedule (unchanged: Daily, every-day)
        await next(tester); // Target

        // With Boolean now paired with the still-Daily period, the Target
        // step must show the fixed case, not the stale "At least 5" from
        // before — proving the earlier edit propagated forward rather than
        // leaving stale cached state in place.
        expect(
          find.byKey(const Key('wizard-fixed-boolean-daily-note')),
          findsOneWidget,
        );
        expect(find.text('At least'), findsNothing);
        expect(nextEnabled(tester), isTrue);
      },
    );
  });

  group('9.4: the UX-DR16 Streak-clarification banner renders for both '
      'contrasted patterns', () {
    const bannerKey = Key('streak-clarification-banner');
    const bannerCopy =
        'Daily goals with cheat days track a real day-by-day Streak. '
        'Weekly-count goals track a single pass/fail per week, with '
        'no daily Streak.';

    testWidgets(
      'Daily period with a configured Cheat Day quota shows the banner on '
      'both the Schedule and Target steps',
      (tester) async {
        final today = _today();
        await openWizard(tester, today);

        await enterName(tester, 'Meditate');
        await next(tester);
        await tester.tap(find.text('Done / not done'));
        await tester.pumpAndSettle();
        await next(tester); // -> Schedule

        // Daily is already the default period, so the Schedule step's
        // broader trigger (period is Daily or Weekly) already shows it.
        expect(find.byKey(bannerKey), findsOneWidget);
        expect(find.text(bannerCopy), findsOneWidget);

        await tester.tap(
          find.byKey(const Key('wizard-cheat-day-quota-increment')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(bannerKey), findsOneWidget);

        await next(tester); // -> Target
        // isDailyCheatDayPattern is now true (Daily + quota > 0), so the
        // Target step's tighter trigger fires too.
        expect(find.byKey(bannerKey), findsOneWidget);
      },
    );

    testWidgets(
      'Weekly period with an At-least/Exactly comparison shows the banner '
      'on both the Schedule and Target steps',
      (tester) async {
        final today = _today();
        await openWizard(tester, today);

        await enterName(tester, 'Gym');
        await next(tester);
        await tester.tap(find.text('Done / not done'));
        await tester.pumpAndSettle();
        await next(tester); // -> Schedule

        await selectDropdownValue(
          tester,
          const Key('wizard-evaluation-period-dropdown'),
          'Weekly',
        );
        expect(find.byKey(bannerKey), findsOneWidget);

        await next(tester); // -> Target
        // Not yet a comparison, so isWeeklyCountPattern is still false.
        expect(find.byKey(bannerKey), findsNothing);

        await tester.tap(find.text('At least'));
        await tester.pumpAndSettle();
        // isWeeklyCountPattern is now true (Weekly + At least).
        expect(find.byKey(bannerKey), findsOneWidget);
      },
    );
  });

  group('9.5: the Review sentence composes correctly for varied '
      'configurations', () {
    DateTime d(int y, int m, int day) => DateTime(y, m, day);

    test('Counter/Daily/At most reads as a per-day limit', () {
      final state = GoalWizardState(
        name: 'Coffee',
        trackingType: TrackingType.counter,
        targetComparison: TargetComparison.atMost,
        targetValueText: '2',
        startDate: d(2026, 8, 18),
      );
      expect(buildReviewSentence(state), 'At most 2 per day, starting Aug 18.');
    });

    test('Weekly/Exactly with an end date reads as a week-level count', () {
      final state = GoalWizardState(
        name: 'Errands',
        trackingType: TrackingType.boolean,
        evaluationPeriodKind: WizardEvaluationPeriodKind.weekly,
        targetComparison: TargetComparison.exactly,
        targetValueText: '2',
        startDate: d(2026, 8, 18),
        endDate: d(2026, 12, 31),
      );
      expect(
        buildReviewSentence(state),
        'Done exactly 2 times a week, starting Aug 18, ending Dec 31.',
      );
    });

    test('Rolling window reads as "in any N days"', () {
      final state = GoalWizardState(
        name: 'Workout',
        trackingType: TrackingType.counter,
        evaluationPeriodKind: WizardEvaluationPeriodKind.rollingWindow,
        rollingWindowDays: 14,
        targetComparison: TargetComparison.atLeast,
        targetValueText: '10',
        startDate: d(2026, 1, 1),
      );
      expect(
        buildReviewSentence(state),
        'Done at least 10 times in any 14 days, starting Jan 1.',
      );
    });

    test('Weekends-only eligible-days phrase renders correctly', () {
      final state = GoalWizardState(
        name: 'Long run',
        trackingType: TrackingType.boolean,
        evaluationPeriodKind: WizardEvaluationPeriodKind.weekly,
        eligibleDaysPattern: const WeekdaySet({6, 7}),
        targetComparison: TargetComparison.atLeast,
        targetValueText: '1',
        startDate: d(2026, 8, 18),
      );
      expect(
        buildReviewSentence(state),
        'Done at least 1 times a week, weekends only, starting Aug 18.',
      );
    });
  });
}
