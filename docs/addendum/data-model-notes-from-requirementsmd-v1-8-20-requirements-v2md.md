# Data Model Notes (from requirements.md v1 §8, §20; requirements-v2.md)

- Suggested `Goal` fields: id, name, description, category, icon, color, enabled, archived, startDate, endDate, hasEndDate, frequency, evaluationRule, targetValue, eligibleDays/eligible dates, cheatDayConfiguration, priority, createdAt, updatedAt.
- Suggested `GoalLog` fields: id, goalId, date, value, completed, note, timestamp.
- v2 implies a three-table split: `goals` / `goal_versions` / `goal_logs`, to support FR-3 (Goal Versioning) without mutating historical evaluation.
- Multiple entries per day per Goal (e.g. logging water intake at 08:00, 12:00, 17:00, 21:00, summed to a daily total) is explicitly named in v1 §21 as architecture that should not be precluded, even if MVP UI only exposes a single aggregated daily value. Not restated as an FR in the PRD because it's a UI/architecture choice, not a product-level capability gap — the aggregate-value behavior (FR-14) is what the product guarantees.
- Priority field on Goal — v1 explicitly left this as "come up with options" (unresolved in the source). Not carried into the PRD as an FR since no resolution exists; flag for UX phase if goal-list ordering needs it.
