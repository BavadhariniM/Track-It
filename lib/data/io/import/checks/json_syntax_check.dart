import 'dart:convert';

/// Subtask 2.1 (AC #2): attempts to parse the raw file contents as JSON,
/// rejecting with a specific "malformed JSON" reason on failure — the first
/// check in the pipeline, since every later check needs a decoded `Map` to
/// operate on.
class JsonSyntaxCheck {
  const JsonSyntaxCheck();

  /// Decodes [raw]. [json] is non-null only when [raw] is syntactically
  /// valid JSON *and* its top-level value is an object (never a bare array,
  /// string, or number) — [rejectionReason] carries the specific reason
  /// otherwise (UX-DR19).
  ({Map<String, dynamic>? json, String? rejectionReason}) decode(String raw) {
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException catch (e) {
      return (
        json: null,
        rejectionReason: 'This file is not valid JSON: ${e.message}.',
      );
    }
    if (decoded is! Map<String, dynamic>) {
      return (
        json: null,
        rejectionReason:
            'This file is not valid JSON: expected a top-level object.',
      );
    }
    return (json: decoded, rejectionReason: null);
  }
}
