import 'parsed_import_file.dart';

/// Subtask 2.10's `Result`/`Either`-style aggregate outcome of running every
/// validation check (Consistency Conventions) — never thrown, always
/// returned.
sealed class ImportValidationResult {
  const ImportValidationResult();
}

/// One of the checks (Subtasks 2.1–2.8) failed. [reason] is the exact
/// UX-DR19-compliant copy naming the specific problem.
final class ImportValidationRejected extends ImportValidationResult {
  const ImportValidationRejected(this.reason);

  final String reason;
}

/// Every check passed. [zeroGoalWarning] is true when the file's `goals`
/// array is empty (AC #8's acceptance exception) — the caller surfaces this
/// as a warning alongside acceptance, never as a rejection.
final class ImportValidationValid extends ImportValidationResult {
  const ImportValidationValid({
    required this.file,
    required this.zeroGoalWarning,
  });

  final ParsedImportFile file;
  final bool zeroGoalWarning;
}
