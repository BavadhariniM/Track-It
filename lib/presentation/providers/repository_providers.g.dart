// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// This is the composition root (AD-1): the only place that binds a
/// domain-defined interface to its concrete `data`-layer implementation.

@ProviderFor(goalRepository)
final goalRepositoryProvider = GoalRepositoryProvider._();

/// This is the composition root (AD-1): the only place that binds a
/// domain-defined interface to its concrete `data`-layer implementation.

final class GoalRepositoryProvider
    extends $FunctionalProvider<GoalRepository, GoalRepository, GoalRepository>
    with $Provider<GoalRepository> {
  /// This is the composition root (AD-1): the only place that binds a
  /// domain-defined interface to its concrete `data`-layer implementation.
  GoalRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalRepositoryHash();

  @$internal
  @override
  $ProviderElement<GoalRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoalRepository create(Ref ref) {
    return goalRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalRepository>(value),
    );
  }
}

String _$goalRepositoryHash() => r'a6543a28f8bc2447be086bfe94c72057c7272533';

@ProviderFor(goalVersionRepository)
final goalVersionRepositoryProvider = GoalVersionRepositoryProvider._();

final class GoalVersionRepositoryProvider
    extends
        $FunctionalProvider<
          GoalVersionRepository,
          GoalVersionRepository,
          GoalVersionRepository
        >
    with $Provider<GoalVersionRepository> {
  GoalVersionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalVersionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalVersionRepositoryHash();

  @$internal
  @override
  $ProviderElement<GoalVersionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GoalVersionRepository create(Ref ref) {
    return goalVersionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalVersionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalVersionRepository>(value),
    );
  }
}

String _$goalVersionRepositoryHash() =>
    r'57a73c42f77e89b78c77d0c4eb1b560e7d8e4de2';

@ProviderFor(goalLogRepository)
final goalLogRepositoryProvider = GoalLogRepositoryProvider._();

final class GoalLogRepositoryProvider
    extends
        $FunctionalProvider<
          GoalLogRepository,
          GoalLogRepository,
          GoalLogRepository
        >
    with $Provider<GoalLogRepository> {
  GoalLogRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'goalLogRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$goalLogRepositoryHash();

  @$internal
  @override
  $ProviderElement<GoalLogRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GoalLogRepository create(Ref ref) {
    return goalLogRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoalLogRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoalLogRepository>(value),
    );
  }
}

String _$goalLogRepositoryHash() => r'a5910d5b7c48d08bcb1ae2766704d10f8a3cf87f';

@ProviderFor(blackoutDateRepository)
final blackoutDateRepositoryProvider = BlackoutDateRepositoryProvider._();

final class BlackoutDateRepositoryProvider
    extends
        $FunctionalProvider<
          BlackoutDateRepository,
          BlackoutDateRepository,
          BlackoutDateRepository
        >
    with $Provider<BlackoutDateRepository> {
  BlackoutDateRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'blackoutDateRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$blackoutDateRepositoryHash();

  @$internal
  @override
  $ProviderElement<BlackoutDateRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BlackoutDateRepository create(Ref ref) {
    return blackoutDateRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BlackoutDateRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BlackoutDateRepository>(value),
    );
  }
}

String _$blackoutDateRepositoryHash() =>
    r'f789856a778ec80800965a3174fdeef39f4cd018';

@ProviderFor(cheatDayRepository)
final cheatDayRepositoryProvider = CheatDayRepositoryProvider._();

final class CheatDayRepositoryProvider
    extends
        $FunctionalProvider<
          CheatDayRepository,
          CheatDayRepository,
          CheatDayRepository
        >
    with $Provider<CheatDayRepository> {
  CheatDayRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cheatDayRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cheatDayRepositoryHash();

  @$internal
  @override
  $ProviderElement<CheatDayRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheatDayRepository create(Ref ref) {
    return cheatDayRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheatDayRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheatDayRepository>(value),
    );
  }
}

String _$cheatDayRepositoryHash() =>
    r'dae80e864da64cb7adceedf771d0fc9e1291cb10';

@ProviderFor(transactionRunner)
final transactionRunnerProvider = TransactionRunnerProvider._();

final class TransactionRunnerProvider
    extends
        $FunctionalProvider<
          TransactionRunner,
          TransactionRunner,
          TransactionRunner
        >
    with $Provider<TransactionRunner> {
  TransactionRunnerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'transactionRunnerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$transactionRunnerHash();

  @$internal
  @override
  $ProviderElement<TransactionRunner> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TransactionRunner create(Ref ref) {
    return transactionRunner(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TransactionRunner value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TransactionRunner>(value),
    );
  }
}

String _$transactionRunnerHash() => r'ac2e79f7455255f3338788cfe57587c4e97b9fe4';

@ProviderFor(statusCacheRepository)
final statusCacheRepositoryProvider = StatusCacheRepositoryProvider._();

final class StatusCacheRepositoryProvider
    extends
        $FunctionalProvider<
          StatusCacheRepository,
          StatusCacheRepository,
          StatusCacheRepository
        >
    with $Provider<StatusCacheRepository> {
  StatusCacheRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'statusCacheRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$statusCacheRepositoryHash();

  @$internal
  @override
  $ProviderElement<StatusCacheRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  StatusCacheRepository create(Ref ref) {
    return statusCacheRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StatusCacheRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StatusCacheRepository>(value),
    );
  }
}

String _$statusCacheRepositoryHash() =>
    r'873ff1f49ba4262c0757885487c7653647faf0e6';

@ProviderFor(cacheWriter)
final cacheWriterProvider = CacheWriterProvider._();

final class CacheWriterProvider
    extends $FunctionalProvider<CacheWriter, CacheWriter, CacheWriter>
    with $Provider<CacheWriter> {
  CacheWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cacheWriterProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cacheWriterHash();

  @$internal
  @override
  $ProviderElement<CacheWriter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CacheWriter create(Ref ref) {
    return cacheWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CacheWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CacheWriter>(value),
    );
  }
}

String _$cacheWriterHash() => r'64f03907eab8aea30a18f67c7405c9317e4e871e';
