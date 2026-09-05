import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/settings/shared_prefs_week_start_settings_repository.dart';
import '../../domain/evaluator/period_boundary.dart';
import '../../domain/services/week_start_settings_repository.dart';
import 'reminder_settings_provider.dart' show sharedPreferencesProvider;

part 'week_start_provider.g.dart';

/// The Week-Start setting (FR-24): which weekday Week View's and Month
/// View's first grid column is, and the exact same value handed to
/// `evaluate()`'s `weekStart` parameter so the visual calendar grid and the
/// evaluator's own Weekly-period boundary calculation never disagree about
/// where a week starts (Story 1.10 Dev Notes).
///
/// Stays a plain, synchronously-watched [WeekStart] (never an `AsyncValue`)
/// for every existing reader (`week_view.dart`, `month_view.dart`,
/// `stats_providers.dart`, `widget_bridge_provider.dart`) — [weekStartInitializerProvider]
/// hydrates it from persisted storage once at startup instead of making this
/// provider itself async. It is overridable in tests via `ProviderScope`
/// overrides, exactly like `goalRepositoryProvider` etc. (see
/// `test/presentation/day_view_test.dart` for the pattern).
@riverpod
class WeekStartSetting extends _$WeekStartSetting {
  @override
  WeekStart build() => WeekStart.monday;

  void set(WeekStart value) => state = value;
}

/// This is the composition root (AD-1/AD-2): the only place that binds
/// [WeekStartSettingsRepository] to its `shared_preferences`-backed
/// implementation (AD-3's settings exception).
@Riverpod(keepAlive: true)
Future<WeekStartSettingsRepository> weekStartSettingsRepository(
  Ref ref,
) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SharedPrefsWeekStartSettingsRepository(prefs);
}

/// Startup hook (mirrors `reminderInitializer`'s "async load, then apply to
/// the synchronous, widely-watched setting" pattern): hydrates
/// [weekStartSettingProvider] from whatever Panda previously chose in
/// Settings, if anything. Watched once from `main.dart`'s composition root.
@Riverpod(keepAlive: true)
Future<void> weekStartInitializer(Ref ref) async {
  final repo = await ref.watch(weekStartSettingsRepositoryProvider.future);
  final stored = await repo.getWeekStart();
  if (stored != null) {
    ref.read(weekStartSettingProvider.notifier).set(stored);
  }
}

/// The Settings screen's write path: persists Panda's Week-Start choice and
/// updates the live [weekStartSettingProvider] in the same step, so Week/
/// Month View and every other reader picks up the change immediately.
/// `keepAlive: true` for the same reason as `ReminderTimeController`: this is
/// invoked via `ref.read` as a plain action call, so nothing else keeps this
/// provider's default auto-dispose lifetime alive across its awaits.
@Riverpod(keepAlive: true)
class WeekStartController extends _$WeekStartController {
  @override
  FutureOr<void> build() {}

  Future<void> setWeekStart(WeekStart value) async {
    final repo = await ref.read(weekStartSettingsRepositoryProvider.future);
    await repo.setWeekStart(value);
    ref.read(weekStartSettingProvider.notifier).set(value);
  }
}
