/// Formats [date] as the naive ISO-8601 date-only string (`YYYY-MM-DD`) used
/// throughout entities and Drift columns (Data conventions, NFR-3) — no
/// timezone, no time-of-day component.
String formatDateOnly(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

const _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [date] as a human-readable display string (e.g. "Aug 26, 2026")
/// for UI surfaces that need a readable date rather than the ISO-8601 form
/// `formatDateOnly` produces.
String formatDisplayDate(DateTime date) {
  return '${_monthAbbreviations[date.month - 1]} ${date.day}, ${date.year}';
}
