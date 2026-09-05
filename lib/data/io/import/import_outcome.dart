import 'conflict_detector.dart';
import 'parsed_import_file.dart';

/// Task 6's `Result`/`Either`-style aggregate outcome of a full import
/// attempt (Consistency Conventions) — never thrown, always returned.
sealed class ImportOutcome {
  const ImportOutcome();
}

/// AC #2–#7: the file failed a validation check. [reason] is the exact
/// UX-DR19-compliant copy naming the specific problem; existing data is
/// provably untouched, since no write is ever issued before every check has
/// passed (Dev Notes: "validate-then-write ordering").
final class ImportOutcomeRejected extends ImportOutcome {
  const ImportOutcomeRejected(this.reason);

  final String reason;
}

/// AC #10: the import finished with no conflicts (or every conflict was
/// already resolved via [JsonImporter.completeWithResolutions]) — every
/// write has already been committed. [zeroGoalWarning] (AC #8) is surfaced
/// as a warning alongside the otherwise-silent success confirmation.
final class ImportOutcomeCompleted extends ImportOutcome {
  const ImportOutcomeCompleted({required this.zeroGoalWarning});

  final bool zeroGoalWarning;
}

/// AC #9: at least one entity id exists in both the file and local data with
/// differing content. No write has been issued yet — [detection] carries
/// both the conflicts Panda must resolve and the non-conflicting entities
/// still waiting to be written, so the caller can hand both to
/// [JsonImporter.completeWithResolutions] once Panda has decided every one.
final class ImportOutcomeNeedsResolution extends ImportOutcome {
  const ImportOutcomeNeedsResolution({
    required this.file,
    required this.detection,
    required this.zeroGoalWarning,
  });

  final ParsedImportFile file;
  final ConflictDetectionResult detection;
  final bool zeroGoalWarning;
}
