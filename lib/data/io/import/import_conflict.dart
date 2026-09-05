/// The five entity types Story 6.2's import can conflict on.
enum ImportEntityType { goal, goalVersion, goalLog, cheatDay, blackoutDate }

/// Panda's decision for one [ImportConflict] (UX-DR14: exactly one decision
/// per conflict, no bulk "accept all"). Deliberately only two cases — a
/// third "merge" option was considered but dropped: for every entity type
/// here, a conflict means the *same id* has different field values on each
/// side, and `GoalService` has no operation that combines two divergent
/// values of the same field into a third value, so a "merge" choice could
/// only ever behave identically to [keepImported] (confirmed with Panda).
enum ConflictChoice { keepMine, keepImported }

/// One same-id, different-content collision between the import file and
/// this device's existing data (AC #9) — "conflict" in the Dev Notes' sense,
/// never a same-file duplicate (see `IntraFileDuplicateIdCheck`'s doc
/// comment for that distinction). [label] is the UX-DR19-compliant copy the
/// resolution card shows verbatim, naming the specific conflicting entity.
class ImportConflict {
  const ImportConflict({
    required this.type,
    required this.id,
    required this.mine,
    required this.imported,
    required this.label,
  });

  final ImportEntityType type;
  final String id;

  /// The entity as it currently exists on this device.
  final Object mine;

  /// The entity as the import file has it.
  final Object imported;

  final String label;

  /// Composite key (`'$type:$id'`) used to key a resolutions map — plain
  /// `id` alone isn't safe to key on across entity types, since ids from
  /// different entity types are independent UUIDv4 namespaces.
  String get resolutionKey => '${type.name}:$id';
}
