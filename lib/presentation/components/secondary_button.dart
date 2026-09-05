import 'package:flutter/material.dart';

import 'design_tokens.dart';

/// The `button-secondary` component (UX-DR10): Back, Cancel, and Edit
/// actions. `PrimaryButton`'s doc comment noted this tier had no use yet as
/// of Story 1.9 — Story 2.1's Goal Detail Edit action is its first use.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.textPrimary,
        side: BorderSide(color: colors.borderHairline),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      child: Text(label),
    );
  }
}
