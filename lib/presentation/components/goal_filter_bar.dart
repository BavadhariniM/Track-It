import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/goal_filter.dart';
import '../providers/goal_data_providers.dart';
import '../providers/goal_filter_provider.dart';
import 'design_tokens.dart';

/// The Calendar surface's filter control (Day/Week/Month) — "All" and each
/// category, as a horizontal `button-secondary`-styled chip row (UX-DR10: no
/// new interactive primitive beyond the two established button tiers).
/// Reads from [allGoalsProvider] (never the already-filtered list) so every
/// choice stays available regardless of which one is currently selected.
class GoalFilterBar extends ConsumerWidget {
  const GoalFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsProvider);
    final selected = ref.watch(selectedGoalFilterProvider);

    return goalsAsync.maybeWhen(
      data: (goals) {
        if (goals.isEmpty) return const SizedBox.shrink();
        final categories = distinctCategories(goals);

        return SizedBox(
          key: const Key('goal-filter-bar'),
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s4,
              vertical: AppSpacing.s2,
            ),
            children: [
              _FilterChip(
                filterKey: const Key('goal-filter-all'),
                label: 'All',
                selected: selected is GoalFilterAll,
                onTap: () => ref
                    .read(selectedGoalFilterProvider.notifier)
                    .setFilter(const GoalFilter.all()),
              ),
              for (final category in categories) ...[
                const SizedBox(width: AppSpacing.s2),
                _FilterChip(
                  filterKey: Key('goal-filter-category-$category'),
                  label: category,
                  selected:
                      selected is GoalFilterCategory &&
                      selected.category == category,
                  onTap: () => ref
                      .read(selectedGoalFilterProvider.notifier)
                      .setFilter(GoalFilter.category(category)),
                ),
              ],
            ],
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// A `button-secondary`-styled selector chip: outlined normally, filled with
/// the accent color when [selected] — the same two-tier button vocabulary
/// (`SecondaryButton`) with only a selected-state color swap, not a new
/// component class.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.filterKey,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final Key filterKey;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return OutlinedButton(
      key: filterKey,
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        backgroundColor: selected ? colors.accent : Colors.transparent,
        foregroundColor: selected ? colors.accentOn : colors.textPrimary,
        side: BorderSide(
          color: selected ? colors.accent : colors.borderHairline,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      ),
      child: Text(label),
    );
  }
}
