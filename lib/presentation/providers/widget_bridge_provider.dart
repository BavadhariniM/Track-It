import 'package:home_widget/home_widget.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/widget_bridge/widget_bridge_writer_impl.dart';
import '../../domain/services/widget_bridge_writer.dart';
import 'repository_providers.dart';
import 'week_start_provider.dart';

part 'widget_bridge_provider.g.dart';

/// iOS App Group suite `home_widget` writes the shared container to (Task
/// 6.1/6.2) — the standard `group.<bundle-id>` convention for the app's
/// bundle id `com.panda.tracker.tracker`. A future WidgetKit extension
/// (Story 5.2) reads the same `UserDefaults` suite via this same id.
const widgetBridgeAppGroupId = 'group.com.panda.tracker.tracker';

/// Composition root (AD-1): binds [WidgetBridgeWriter] to its `data`-layer
/// implementation, the same pattern `cacheWriterProvider` uses.
@Riverpod(keepAlive: true)
WidgetBridgeWriter widgetBridgeWriter(Ref ref) {
  return WidgetBridgeWriterImpl(
    goalRepository: ref.watch(goalRepositoryProvider),
    goalVersionRepository: ref.watch(goalVersionRepositoryProvider),
    statusCacheRepository: ref.watch(statusCacheRepositoryProvider),
    weekStart: ref.watch(weekStartSettingProvider),
    appGroupId: widgetBridgeAppGroupId,
  );
}

/// Composition-root startup hook (Task 6.2): sets the iOS App Group id once
/// per app launch so every `HomeWidget.saveWidgetData`/`updateWidget` call
/// targets the shared container a future WidgetKit extension (Story 5.2)
/// reads from. A no-op on Android, which has no App Group concept.
@Riverpod(keepAlive: true)
Future<void> widgetBridgeInitializer(Ref ref) async {
  await HomeWidget.setAppGroupId(widgetBridgeAppGroupId);
}
