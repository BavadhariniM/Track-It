import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/services/goal_service.dart';
import 'repository_providers.dart';
import 'widget_bridge_provider.dart';

part 'goal_service_provider.g.dart';

@Riverpod(keepAlive: true)
GoalService goalService(Ref ref) {
  return GoalService(
    goalRepository: ref.watch(goalRepositoryProvider),
    goalVersionRepository: ref.watch(goalVersionRepositoryProvider),
    goalLogRepository: ref.watch(goalLogRepositoryProvider),
    blackoutDateRepository: ref.watch(blackoutDateRepositoryProvider),
    cheatDayRepository: ref.watch(cheatDayRepositoryProvider),
    transactionRunner: ref.watch(transactionRunnerProvider),
    cacheWriter: ref.watch(cacheWriterProvider),
    widgetBridgeWriter: ref.watch(widgetBridgeWriterProvider),
  );
}
