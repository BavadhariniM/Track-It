import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/entities/rule_values.dart';
import 'package:tracker/domain/evaluator/date_format.dart';
import 'package:tracker/presentation/components/goal_row.dart';
import 'package:tracker/presentation/providers/repository_providers.dart';
import 'package:tracker/presentation/screens/day_view.dart';

import '../domain/services/fakes.dart';

/// Story 3.5 added a per-goal filter chip (`GoalFilterBar`) that also
/// renders each goal's name as text, so a bare `find.text(name)` is
/// ambiguous once a goal exists — this scopes to the actual `GoalRow`.
Finder _goalRow(String name) => find.widgetWithText(GoalRow, name);

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

  testWidgets('shows the first-run empty state when there are no goals', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(DateTime.now()));
    await tester.pumpAndSettle();

    expect(find.text('No goals yet'), findsOneWidget);
    expect(find.text('Create Goal'), findsOneWidget);
  });

  testWidgets('titles the AppBar "Today" when the screen shows the actual '
      'current date', (tester) async {
    await tester.pumpWidget(buildApp(DateTime.now()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Today'), findsOneWidget);
  });

  testWidgets('titles the AppBar with the picked date, not "Today", when a '
      'different day is opened (Bug 1)', (tester) async {
    final notToday = DateTime.now().add(const Duration(days: 10));

    await tester.pumpWidget(buildApp(notToday));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(AppBar, formatDisplayDate(notToday)),
      findsOneWidget,
    );
    expect(find.widgetWithText(AppBar, 'Today'), findsNothing);
  });

  testWidgets('creating a goal renders it as a goal-row with a Done label', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(DateTime.now()));
    await tester.pumpAndSettle();

    await _createGoalViaWizard(tester, name: 'Read');

    expect(_goalRow('Read'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
  });

  testWidgets(
    'tapping the goal row logs it done through GoalService and re-renders Success',
    (tester) async {
      await tester.pumpWidget(buildApp(DateTime.now()));
      await tester.pumpAndSettle();

      await _createGoalViaWizard(tester, name: 'Read');

      await tester.tap(_goalRow('Read'));
      await tester.pumpAndSettle();

      expect(store.logs, hasLength(1));
      expect(store.logs.single.completed, isTrue);
      expect(find.text('✓'), findsOneWidget);

      // Tapping again must undo the mistaken mark-done and restore the
      // row's previous state (Pending, not Fail) by retracting the log
      // rather than appending an explicit not-done record (Bug 4).
      await tester.tap(_goalRow('Read'));
      await tester.pumpAndSettle();
      expect(store.logs, isEmpty);
      expect(find.text('…'), findsOneWidget);
    },
  );

  testWidgets(
    'creating a Counter goal and stepping it up updates the goal-row fraction',
    (tester) async {
      await tester.pumpWidget(buildApp(DateTime.now()));
      await tester.pumpAndSettle();

      await _createGoalViaWizard(tester, name: 'Water', counter: true);

      expect(_goalRow('Water'), findsOneWidget);
      expect(find.text('0/8'), findsOneWidget);

      await tester.tap(_goalRow('Water'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Increase by 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Increase by 1'));
      await tester.pumpAndSettle();

      expect(store.logs, hasLength(1));
      expect(store.logs.single.value, 2);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('2/8'), findsOneWidget);
    },
  );

  testWidgets(
    'a Workdays-only goal renders no row at all on a Saturday (Bug 7 — a '
    "goal not scheduled for a date doesn't appear on it, rather than "
    'rendering as an empty/"Not eligible" dash)',
    (tester) async {
      final saturday = _nextSaturdayOnOrAfterToday();
      await tester.pumpWidget(buildApp(saturday));
      await tester.pumpAndSettle();

      await _createGoalViaWizard(
        tester,
        name: 'Gym',
        eligibleDaysPreset: 'Workdays',
      );

      expect(_goalRow('Gym'), findsNothing);
    },
  );

  testWidgets(
    'long-pressing a goal row opens the Blackout Date sheet, which marks '
    'the date and re-renders the row as Empty',
    (tester) async {
      await tester.pumpWidget(buildApp(DateTime.now()));
      await tester.pumpAndSettle();

      await _createGoalViaWizard(tester, name: 'Read');

      await tester.longPress(_goalRow('Read'));
      await tester.pumpAndSettle();

      expect(find.text('Mark as Blackout Date'), findsWidgets);

      await tester.enterText(
        find.widgetWithText(TextField, 'Reason (optional)'),
        'Public holiday',
      );
      await tester.tap(find.text('Mark as Blackout Date').last);
      await tester.pumpAndSettle();

      expect(store.blackoutDates, hasLength(1));
      expect(store.blackoutDates.single.reason, 'Public holiday');
      expect(find.text('–'), findsOneWidget);
    },
  );

  testWidgets(
    "a blackout date already excluded by the goal's own weekday rule "
    'still renders the row (Bug 7 edge case: a blackout is a deliberate '
    'user action and always wins over the eligibility guard)',
    (tester) async {
      final saturday = _nextSaturdayOnOrAfterToday();
      await tester.pumpWidget(buildApp(saturday));
      await tester.pumpAndSettle();

      // Created with the default "Every day" schedule so the row (and its
      // long-press target) is visible on this Saturday when the blackout
      // is marked.
      await _createGoalViaWizard(tester, name: 'Gym');
      expect(_goalRow('Gym'), findsOneWidget);

      await tester.longPress(_goalRow('Gym'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Reason (optional)'),
        'Injured',
      );
      await tester.tap(find.text('Mark as Blackout Date').last);
      await tester.pumpAndSettle();
      expect(store.blackoutDates, hasLength(1));

      // Simulate a Story 2.1 mid-stream rule edit that narrows the
      // schedule to Workdays-only, after the blackout already exists on
      // this Saturday.
      final narrowedVersion = store.versions.single.copyWith(
        eligibleDaysRule: EligibleDaysRule.workdays,
      );
      await InMemoryGoalVersionRepository(store).updateVersion(narrowedVersion);
      await tester.pumpAndSettle();

      expect(_goalRow('Gym'), findsOneWidget);
      expect(find.text('–'), findsOneWidget);
    },
  );

  testWidgets(
    'the DNF badge appears once marked while Pending, and disappears once '
    'the day resolves to Success (Counter goal, where the placeholder '
    "value=0 log can't be misread as an explicit fail)",
    (tester) async {
      await tester.pumpWidget(buildApp(DateTime.now()));
      await tester.pumpAndSettle();

      await _createGoalViaWizard(
        tester,
        name: 'Water',
        counter: true,
        targetValue: '2',
      );

      await tester.longPress(_goalRow('Water'));
      await tester.pumpAndSettle();

      expect(find.text('Mark DNF'), findsWidgets);
      await tester.ensureVisible(find.text('Mark DNF').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark DNF').last);
      await tester.pumpAndSettle();

      expect(store.logs, hasLength(1));
      expect(store.logs.single.dnfMarked, isTrue);
      expect(find.text('DNF · pending period close'), findsOneWidget);

      // Stepping the counter up to target resolves the day to Success — the
      // badge must stop rendering once DayStatus != pending (Task 4.3).
      await tester.tap(_goalRow('Water'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Increase by 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Increase by 1'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('DNF · pending period close'), findsNothing);
    },
  );

  testWidgets(
    'long-pressing an already-resolved day never offers Mark DNF',
    (tester) async {
      await tester.pumpWidget(buildApp(DateTime.now()));
      await tester.pumpAndSettle();

      await _createGoalViaWizard(tester, name: 'Read');
      await tester.tap(_goalRow('Read'));
      await tester.pumpAndSettle();

      await tester.longPress(_goalRow('Read'));
      await tester.pumpAndSettle();

      expect(find.text('Mark DNF'), findsNothing);
    },
  );

  testWidgets(
    'known caveat: on a Daily/Boolean goal, DNF\'s placeholder log reads as '
    'an immediate Fail rather than the Pending badge, since evaluate() '
    "can't yet distinguish a DNF placeholder from an explicit fail-log for "
    'this goal shape (accepted for now; see Story 2.5 Dev Agent notes)',
    (tester) async {
      await tester.pumpWidget(buildApp(DateTime.now()));
      await tester.pumpAndSettle();

      await _createGoalViaWizard(tester, name: 'Read');

      await tester.longPress(_goalRow('Read'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Mark DNF').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark DNF').last);
      await tester.pumpAndSettle();

      expect(store.logs.single.dnfMarked, isTrue);
      expect(find.text('DNF · pending period close'), findsNothing);
      expect(find.text('✕'), findsOneWidget);
    },
  );

  testWidgets('a paused date omits the goal-row entirely — never Empty, never '
      'Pending (Story 2.2 AC 2)', (tester) async {
    await tester.pumpWidget(buildApp(DateTime.now()));
    await tester.pumpAndSettle();

    await _createGoalViaWizard(tester, name: 'Read');
    expect(_goalRow('Read'), findsOneWidget);

    final pausedVersion = store.versions.single.copyWith(isPaused: true);
    await InMemoryGoalVersionRepository(store).updateVersion(pausedVersion);
    await tester.pumpAndSettle();

    expect(_goalRow('Read'), findsNothing);
    // The goal still exists — Create Goal's FAB stays available, this is
    // not the empty-state.
    expect(find.text('No goals yet'), findsNothing);
  });

  testWidgets('an archived goal omits the goal-row entirely (Story 2.3 AC 2)', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(DateTime.now()));
    await tester.pumpAndSettle();

    await _createGoalViaWizard(tester, name: 'Read');
    expect(_goalRow('Read'), findsOneWidget);

    final goal = store.goals.single.copyWith(archived: true);
    await InMemoryGoalRepository(store).updateGoal(goal);
    await tester.pumpAndSettle();

    expect(_goalRow('Read'), findsNothing);
  });

  testWidgets(
    'a date before the goal\'s startDate omits the goal-row entirely, and '
    'it reappears once startDate is reached (Bug 5)',
    (tester) async {
      await tester.pumpWidget(buildApp(DateTime.now()));
      await tester.pumpAndSettle();

      await _createGoalViaWizard(tester, name: 'Read');
      expect(_goalRow('Read'), findsOneWidget);

      final originalGoal = store.goals.single;
      final future = DateTime.now().add(const Duration(days: 5));
      await InMemoryGoalRepository(store).updateGoal(
        originalGoal.copyWith(startDate: formatDateOnly(future)),
      );
      await tester.pumpAndSettle();

      expect(_goalRow('Read'), findsNothing);

      await InMemoryGoalRepository(store).updateGoal(
        originalGoal.copyWith(startDate: formatDateOnly(DateTime.now())),
      );
      await tester.pumpAndSettle();

      expect(_goalRow('Read'), findsOneWidget);
    },
  );
}

/// Drives the Story 1.9 guided wizard (name → tracking type → schedule →
/// target → dates → reminders → review) from the Day View's "Create Goal"
/// entry point through to Save, using every step's default/simplest valid
/// answer except for the axes a given test cares about. Every step widget
/// is keyed (`wizard-*`) precisely so this kind of end-to-end drive doesn't
/// depend on fragile text lookups for controls that repeat across steps.
Future<void> _createGoalViaWizard(
  WidgetTester tester, {
  required String name,
  bool counter = false,
  String? eligibleDaysPreset,
  String targetComparisonLabel = 'At least',
  String targetValue = '8',
}) async {
  await tester.tap(find.text('Create Goal'));
  await tester.pumpAndSettle();

  // Step 1: Name. A settle is required before tapping Next: entering text
  // only marks the field dirty, and Next's enabled state (derived from the
  // wizard state that setName's onChanged callback updates) doesn't
  // reflect the new text until that pending rebuild is flushed.
  await tester.enterText(const Key('wizard-name-field').toFinder(), name);
  await tester.pumpAndSettle();
  await _wizardNext(tester);

  // Step 2: Tracking Type.
  await tester.tap(find.text(counter ? 'Counter' : 'Done / not done'));
  await tester.pumpAndSettle();
  await _wizardNext(tester);

  // Step 3: Schedule — defaults to Daily + every day; only interact with
  // the eligible-days preset when a test cares which days are eligible.
  if (eligibleDaysPreset != null) {
    await tester.tap(find.text(eligibleDaysPreset));
    await tester.pumpAndSettle();
  }
  await _wizardNext(tester);

  // Step 4: Target — a Boolean/Daily goal is fixed (no comparison/value
  // needed, per GoalWizardState.isFixedBooleanDaily); a Counter goal needs
  // both picked before Next enables.
  if (counter) {
    await tester.tap(find.text(targetComparisonLabel));
    await tester.pumpAndSettle();
    await tester.enterText(
      const Key('wizard-target-value-field').toFinder(),
      targetValue,
    );
    await tester.pumpAndSettle();
  }
  await _wizardNext(tester);

  // Step 5: Dates — defaults (start today, no end date) are already valid.
  await _wizardNext(tester);

  // Step 6: Reminders — always valid.
  await _wizardNext(tester);

  // Step 7: Review — Save.
  await tester.tap(const Key('wizard-save-button').toFinder());
  await tester.pumpAndSettle();
}

Future<void> _wizardNext(WidgetTester tester) async {
  await tester.tap(const Key('wizard-next-button').toFinder());
  await tester.pumpAndSettle();
}

extension on Key {
  Finder toFinder() => find.byKey(this);
}

DateTime _nextSaturdayOnOrAfterToday() {
  final today = DateTime.now();
  final daysUntilSaturday = (DateTime.saturday - today.weekday) % 7;
  return DateTime(
    today.year,
    today.month,
    today.day,
  ).add(Duration(days: daysUntilSaturday));
}
