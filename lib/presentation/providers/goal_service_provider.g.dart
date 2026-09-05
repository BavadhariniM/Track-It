// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(goalService)
final goalServiceProvider = GoalServiceProvider._();

final class GoalServiceProvider
    extends $FunctionalProvider<GoalService, GoalService, GoalService>
    with $Provider<GoalService> {
  GoalServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalServiceHash();

  @$internal
  @override
  $ProviderElement<GoalService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalService create(Ref ref) {
    return goalService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalService>(value),
    );
  }
}

String _$goalServiceHash() => r'6bbe5a863175eb45123b7df5c58496928ecec775';
