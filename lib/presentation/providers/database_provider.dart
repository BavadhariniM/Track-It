import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/drift/database.dart';

part 'database_provider.g.dart';

/// The single [AppDatabase] instance for the app, wired as a singleton
/// exclusively through this Riverpod provider (AD-2) — never a
/// global/static accessor.
@Riverpod(keepAlive: true)
AppDatabase appDatabase(Ref ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
}
