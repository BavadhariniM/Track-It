package com.panda.tracker.tracker.widget

import org.json.JSONObject

/** One `(date, goalId)` cell from Story 5.1's shared-container envelope. */
data class WidgetCell(
    val date: String,
    val goalId: String,
    val goalName: String,
    val status: String,
)

/** The JSON envelope shape fixed by Story 5.1 — do not diverge from it. */
data class WidgetEnvelope(
    val scope: String,
    val generatedAt: String,
    val rangeStart: String,
    val rangeEnd: String,
    val isEmpty: Boolean,
    val cells: List<WidgetCell>,
)

/**
 * Decodes the raw JSON string `home_widget` deposited in the shared
 * container. Pure parsing only — this is the only operation this file
 * performs on the payload; it never derives a status, count, or comparison
 * from raw values (AD-7's cache-only rule, restated for native code).
 * Returns `null` for a missing/blank value (no data has been written yet).
 */
fun parseWidgetEnvelope(json: String?): WidgetEnvelope? {
    if (json.isNullOrEmpty()) return null
    val obj = JSONObject(json)
    val cellsArray = obj.optJSONArray("cells")
    val cells = buildList {
        if (cellsArray != null) {
            for (i in 0 until cellsArray.length()) {
                val cell = cellsArray.getJSONObject(i)
                add(
                    WidgetCell(
                        date = cell.getString("date"),
                        goalId = cell.getString("goalId"),
                        goalName = cell.getString("goalName"),
                        status = cell.getString("status"),
                    )
                )
            }
        }
    }
    return WidgetEnvelope(
        scope = obj.optString("scope"),
        generatedAt = obj.optString("generatedAt"),
        rangeStart = obj.optString("rangeStart"),
        rangeEnd = obj.optString("rangeEnd"),
        isEmpty = obj.optBoolean("isEmpty", cells.isEmpty()),
        cells = cells,
    )
}
