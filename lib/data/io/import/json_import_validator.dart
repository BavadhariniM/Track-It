import 'checks/cheat_day_config_check.dart';
import 'checks/date_validity_check.dart';
import 'checks/intra_file_duplicate_id_check.dart';
import 'checks/json_syntax_check.dart';
import 'checks/orphaned_reference_check.dart';
import 'checks/required_structure_check.dart';
import 'checks/rule_contradiction_check.dart';
import 'checks/schema_version_check.dart';
import 'checks/zero_goal_warning_check.dart';
import 'import_validation_result.dart';
import 'parsed_import_file.dart';

/// Subtask 2.10: runs every discrete validation check (Subtasks 2.1–2.9) to
/// completion, in the order each check's own doc comment declares as a
/// dependency, before any write occurs (Dev Notes: "validate-then-write
/// ordering is what makes 'existing data left untouched' true"). Stops at
/// the first failing check — later checks may assume every earlier one has
/// already passed (e.g. [SchemaVersionCheck] assumes
/// [RequiredStructureCheck] already confirmed `meta.schemaVersion` exists).
class JsonImportValidator {
  const JsonImportValidator();

  static const _jsonSyntaxCheck = JsonSyntaxCheck();
  static const _requiredStructureCheck = RequiredStructureCheck();
  static const _schemaVersionCheck = SchemaVersionCheck();
  static const _intraFileDuplicateIdCheck = IntraFileDuplicateIdCheck();
  static const _orphanedReferenceCheck = OrphanedReferenceCheck();
  static const _dateValidityCheck = DateValidityCheck();
  static const _ruleContradictionCheck = RuleContradictionCheck();
  static const _cheatDayConfigCheck = CheatDayConfigCheck();
  static const _zeroGoalWarningCheck = ZeroGoalWarningCheck();

  ImportValidationResult validate(
    String raw, {
    required Set<String> existingLocalGoalIds,
  }) {
    final decoded = _jsonSyntaxCheck.decode(raw);
    if (decoded.rejectionReason != null) {
      return ImportValidationRejected(decoded.rejectionReason!);
    }
    final json = decoded.json!;

    final structureFailure = _requiredStructureCheck.check(json);
    if (structureFailure != null) {
      return ImportValidationRejected(structureFailure);
    }

    final schemaVersionFailure = _schemaVersionCheck.check(json);
    if (schemaVersionFailure != null) {
      return ImportValidationRejected(schemaVersionFailure);
    }

    final duplicateIdFailure = _intraFileDuplicateIdCheck.check(json);
    if (duplicateIdFailure != null) {
      return ImportValidationRejected(duplicateIdFailure);
    }

    final orphanFailure = _orphanedReferenceCheck.check(
      json,
      existingLocalGoalIds,
    );
    if (orphanFailure != null) {
      return ImportValidationRejected(orphanFailure);
    }

    final dateFailure = _dateValidityCheck.check(json);
    if (dateFailure != null) {
      return ImportValidationRejected(dateFailure);
    }

    final ruleFailure = _ruleContradictionCheck.check(json);
    if (ruleFailure != null) {
      return ImportValidationRejected(ruleFailure);
    }

    final cheatDayConfigFailure = _cheatDayConfigCheck.check(json);
    if (cheatDayConfigFailure != null) {
      return ImportValidationRejected(cheatDayConfigFailure);
    }

    return ImportValidationValid(
      file: ParsedImportFile.fromJson(json),
      zeroGoalWarning: _zeroGoalWarningCheck.appliesTo(json),
    );
  }
}
