/// Domain-defined, Drift-agnostic abstraction for "run these writes as one
/// atomic unit" (Transaction atomicity convention, AD-6). Implemented by a
/// Drift-backed runner in `data/repositories/` that wraps the action in a
/// single Drift transaction — a kill mid-save loses at most the one
/// in-flight action, never a partial write.
abstract interface class TransactionRunner {
  Future<T> run<T>(Future<T> Function() action);
}
