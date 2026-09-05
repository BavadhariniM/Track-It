package com.panda.tracker.tracker.widget

import androidx.annotation.ColorRes
import com.panda.tracker.tracker.R

/**
 * The exact color/glyph/label vocabulary from `DESIGN.md`'s color tokens
 * (Story 5.2 Dev Notes table). Every widget cell's color/glyph/label is a
 * direct lookup from this table keyed on the `status` string already
 * present in the decoded JSON — no arithmetic, no comparison against a
 * target, no re-implementation of any evaluation concept (AD-7).
 */
data class StatusPresentation(
    @ColorRes val backgroundColorRes: Int,
    @ColorRes val onColorRes: Int,
    val glyph: String,
    val labelWord: String,
)

private val statusPresentations = mapOf(
    "success" to StatusPresentation(
        R.color.status_success_bg,
        R.color.status_success_on,
        "✓",
        "Success",
    ),
    "fail" to StatusPresentation(
        R.color.status_fail_bg,
        R.color.status_fail_on,
        "✕",
        "Failed",
    ),
    "cheat" to StatusPresentation(
        R.color.status_cheat_bg,
        R.color.status_cheat_on,
        "C",
        "Cheat day used",
    ),
    "pending" to StatusPresentation(
        R.color.status_pending_bg,
        R.color.status_pending_on,
        "…",
        "Pending",
    ),
    "empty" to StatusPresentation(
        R.color.status_empty_bg,
        R.color.status_empty_on,
        "–",
        "Not scheduled",
    ),
)

/** Falls back to the "empty" treatment for any unrecognized status string. */
fun presentationFor(status: String): StatusPresentation =
    statusPresentations[status] ?: statusPresentations.getValue("empty")

/**
 * "<goal>, <state>" for the Today widget's per-goal dot; "<goal>, <date>,
 * <state>" for Week/Month grid cells, matching EXPERIENCE.md's Accessibility
 * Floor pattern so a screen-reader user gets both axes.
 */
fun statusLabel(goalName: String, status: String, date: String? = null): String {
    val word = presentationFor(status).labelWord
    return if (date != null) "$goalName, $date, $word" else "$goalName, $word"
}
