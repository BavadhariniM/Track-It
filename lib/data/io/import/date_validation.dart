/// Naive ISO-8601 date-only string validity (`YYYY-MM-DD`) — shared by every
/// import validation check that needs to confirm a date field actually
/// round-trips. Dart's `DateTime.parse` silently *normalizes* an
/// out-of-range calendar date like `2026-02-30` into March 2 rather than
/// throwing, so this re-formats the parsed result and compares it back
/// against the original string to catch that case (Subtask 2.6, AC #7).
bool isValidDateOnly(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  try {
    final parsed = DateTime.parse(value);
    final y = parsed.year.toString().padLeft(4, '0');
    final m = parsed.month.toString().padLeft(2, '0');
    final d = parsed.day.toString().padLeft(2, '0');
    return '$y-$m-$d' == value;
  } on FormatException {
    return false;
  }
}
