import '../../domain/services/transaction_runner.dart';
import '../drift/database.dart';

/// Wraps [action] in a single Drift transaction (Transaction atomicity
/// convention, AD-6): a kill mid-save loses at most this one in-flight
/// write; all previously committed data survives.
class DriftTransactionRunner implements TransactionRunner {
  DriftTransactionRunner(this._db);

  final AppDatabase _db;

  @override
  Future<T> run<T>(Future<T> Function() action) {
    return _db.transaction(action);
  }
}
