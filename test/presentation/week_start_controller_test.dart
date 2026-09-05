import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tracker/domain/evaluator/period_boundary.dart';
import 'package:tracker/domain/services/week_start_settings_repository.dart';
import 'package:tracker/presentation/providers/week_start_provider.dart';

/// In-memory fake standing in for `SharedPrefsWeekStartSettingsRepository` —
/// exercises [WeekStartController] and [weekStartInitializerProvider]
/// without any real `shared_preferences` I/O.
class FakeWeekStartSettingsRepository implements WeekStartSettingsRepository {
  WeekStart? stored;

  @override
  Future<WeekStart?> getWeekStart() async => stored;

  @override
  Future<void> setWeekStart(WeekStart value) async => stored = value;

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  late FakeWeekStartSettingsRepository repository;

  // Every real reader of `weekStartSettingProvider` (week_view.dart,
  // month_view.dart, etc.) uses `ref.watch`, which is what keeps this
  // `@riverpod` (autoDispose) notifier's state alive between reads — a bare
  // `ref.read` with no active watcher can let it dispose and reset to its
  // default before a later read. This helper widget mirrors that by
  // watching it once and surfacing both the current value and the `ref`.
  Widget buildApp({required Widget child}) {
    return ProviderScope(
      overrides: [
        weekStartSettingsRepositoryProvider.overrideWith((ref) => repository),
      ],
      child: MaterialApp(
        home: Consumer(
          builder: (context, ref, _) {
            ref.watch(weekStartSettingProvider);
            return child;
          },
        ),
      ),
    );
  }

  setUp(() {
    repository = FakeWeekStartSettingsRepository();
  });

  testWidgets(
    'setWeekStart writes through the repository and updates the live '
    'weekStartSettingProvider in the same step',
    (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        buildApp(
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        capturedRef.read(weekStartSettingProvider),
        WeekStart.monday,
      );

      await capturedRef
          .read(weekStartControllerProvider.notifier)
          .setWeekStart(WeekStart.sunday);

      expect(repository.stored, WeekStart.sunday);
      expect(capturedRef.read(weekStartSettingProvider), WeekStart.sunday);
    },
  );

  testWidgets(
    'weekStartInitializer hydrates the live setting from whatever was '
    'previously persisted',
    (tester) async {
      repository.stored = WeekStart.sunday;

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        buildApp(
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await capturedRef.read(weekStartInitializerProvider.future);
      await tester.pumpAndSettle();

      expect(capturedRef.read(weekStartSettingProvider), WeekStart.sunday);
    },
  );

  testWidgets(
    'weekStartInitializer leaves the default untouched when nothing was ever '
    'persisted',
    (tester) async {
      late WidgetRef capturedRef;
      await tester.pumpWidget(
        buildApp(
          child: Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await capturedRef.read(weekStartInitializerProvider.future);
      await tester.pumpAndSettle();

      expect(capturedRef.read(weekStartSettingProvider), WeekStart.monday);
    },
  );
}
