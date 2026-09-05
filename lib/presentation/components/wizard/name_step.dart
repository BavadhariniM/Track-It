import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/services/goal_filter.dart';
import '../../providers/goal_data_providers.dart';
import '../../providers/goal_wizard_provider.dart';
import '../design_tokens.dart';

/// Step 1: goal name (required) and optional description (Subtask 2.1) —
/// `Goal.name`/`description`, Story 1.1's entity fields.
class NameStep extends ConsumerStatefulWidget {
  const NameStep({super.key});

  @override
  ConsumerState<NameStep> createState() => _NameStepState();
}

class _NameStepState extends ConsumerState<NameStep> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(goalWizardProvider);
    _nameController = TextEditingController(text: state.name);
    _descriptionController = TextEditingController(
      text: state.description ?? '',
    );
    _categoryController = TextEditingController(text: state.category ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  void _selectCategory(String category) {
    _categoryController.text = category;
    ref.read(goalWizardProvider.notifier).setCategory(category);
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final isEditMode = ref.watch(goalWizardProvider).isEditMode;
    return ListView(
      children: [
        Text(
          'What do you want to track?',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.s4),
        // Story 2.1 scope is schedule/target edits only (AC 1) — the Goal's
        // name/description have no field on `GoalVersionDraft`, so
        // `editGoalVersion` never persists a change made here. Fields stay
        // read-only in edit mode rather than silently discarding an edit.
        TextField(
          key: const Key('wizard-name-field'),
          controller: _nameController,
          autofocus: !isEditMode,
          enabled: !isEditMode,
          decoration: InputDecoration(
            labelText: 'Goal name',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onChanged: (value) =>
              ref.read(goalWizardProvider.notifier).setName(value),
        ),
        const SizedBox(height: AppSpacing.s3),
        TextField(
          key: const Key('wizard-description-field'),
          controller: _descriptionController,
          enabled: !isEditMode,
          decoration: InputDecoration(
            labelText: 'Description (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onChanged: (value) =>
              ref.read(goalWizardProvider.notifier).setDescription(value),
        ),
        if (isEditMode) ...[
          const SizedBox(height: AppSpacing.s2),
          Text(
            "Name and description aren't editable here.",
            style: TextStyle(color: colors.textMuted),
          ),
        ],
        const SizedBox(height: AppSpacing.s3),
        // Story 3.5 Subtask 1.1/1.2: category is goal-identity metadata,
        // not a scheduling/target axis — it stays editable in edit mode
        // even though name/description above don't, since changing it is a
        // direct `GOAL` row update (never a new `GoalVersion`).
        TextField(
          key: const Key('wizard-category-field'),
          controller: _categoryController,
          decoration: InputDecoration(
            labelText: 'Category (optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
          ),
          onChanged: (value) =>
              ref.read(goalWizardProvider.notifier).setCategory(value),
        ),
        Consumer(
          builder: (context, ref, _) {
            final goals = ref.watch(allGoalsProvider).value ?? const [];
            final categories = distinctCategories(goals);
            if (categories.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: AppSpacing.s2),
              child: Wrap(
                spacing: AppSpacing.s2,
                runSpacing: AppSpacing.s2,
                children: [
                  for (final category in categories)
                    ActionChip(
                      key: Key('wizard-category-suggestion-$category'),
                      label: Text(category),
                      onPressed: () => _selectCategory(category),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
