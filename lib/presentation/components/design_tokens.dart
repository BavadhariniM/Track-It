import 'package:flutter/material.dart';

/// Colors from `docs/ux-designs/ux-Tracker-2026-08-17/DESIGN.md`'s
/// front-matter. These are the only colors permitted anywhere in this
/// story's screens (UX-DR1) — no ad hoc hex values.
class AppColors {
  const AppColors({
    required this.bgBase,
    required this.bgSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.borderHairline,
    required this.accent,
    required this.accentOn,
    required this.statusSuccess,
    required this.statusSuccessOn,
    required this.statusFail,
    required this.statusFailOn,
    required this.statusCheat,
    required this.statusCheatOn,
    required this.statusEmpty,
    required this.statusEmptyOn,
    required this.statusPending,
    required this.statusPendingOn,
  });

  final Color bgBase;
  final Color bgSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color borderHairline;
  final Color accent;
  final Color accentOn;
  final Color statusSuccess;
  final Color statusSuccessOn;
  final Color statusFail;
  final Color statusFailOn;
  final Color statusCheat;
  final Color statusCheatOn;
  final Color statusEmpty;
  final Color statusEmptyOn;
  final Color statusPending;
  final Color statusPendingOn;

  static const light = AppColors(
    bgBase: Color(0xFFF4F6F8),
    bgSurface: Color(0xFFFFFFFF),
    textPrimary: Color(0xFF101828),
    textSecondary: Color(0xFF475467),
    textMuted: Color(0xFF98A2B3),
    borderHairline: Color(0xFFE4E7EC),
    accent: Color(0xFF2E6F8E),
    accentOn: Color(0xFFFFFFFF),
    statusSuccess: Color(0xFF2F9E67),
    statusSuccessOn: Color(0xFFFFFFFF),
    statusFail: Color(0xFFD34A4A),
    statusFailOn: Color(0xFFFFFFFF),
    statusCheat: Color(0xFFD6A631),
    statusCheatOn: Color(0xFF3A2A05),
    statusEmpty: Color(0xFFE4E7EC),
    statusEmptyOn: Color(0xFF98A2B3),
    statusPending: Color(0xFF6B7CA0),
    statusPendingOn: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    bgBase: Color(0xFF0E1520),
    bgSurface: Color(0xFF141C2A),
    textPrimary: Color(0xFFE6EAF0),
    textSecondary: Color(0xFF9AA6B8),
    textMuted: Color(0xFF5C6B82),
    borderHairline: Color(0xFF26314A),
    accent: Color(0xFF5DA8CC),
    accentOn: Color(0xFF0E1520),
    statusSuccess: Color(0xFF3FBE82),
    statusSuccessOn: Color(0xFF0E1520),
    statusFail: Color(0xFFE5675F),
    statusFailOn: Color(0xFFFFFFFF),
    statusCheat: Color(0xFFE3B94E),
    statusCheatOn: Color(0xFF2A1E02),
    statusEmpty: Color(0xFF26314A),
    statusEmptyOn: Color(0xFF5C6B82),
    statusPending: Color(0xFF8B9BC7),
    statusPendingOn: Color(0xFF101828),
  );

  static AppColors of(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark ? dark : light;
  }
}

/// `{rounded}` tokens.
abstract final class AppRadius {
  static const sm = 6.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const full = 9999.0;
}

/// `{spacing}` tokens — a plain 4px/8px ramp.
abstract final class AppSpacing {
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 24.0;
  static const s6 = 32.0;
  static const s7 = 48.0;
}

/// `{typography.numeric}` — the one departure from platform-default type:
/// tabular figures so digits don't shift width as a live value updates
/// (Counter entry, streak counts, stat cards — Story 1.2 establishes the
/// pattern for those later stories to reuse).
abstract final class AppTypography {
  static TextStyle numeric(
    Color color, {
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}

/// Formats a numeric value without a trailing `.0` for whole numbers, while
/// preserving decimals (e.g. `8` not `8.0`, but `7.5` stays `7.5`).
String formatNumeric(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}
