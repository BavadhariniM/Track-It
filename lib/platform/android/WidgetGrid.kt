package com.panda.tracker.tracker.widget

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.LocalContext
import androidx.glance.LocalSize
import androidx.glance.action.clickable
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.panda.tracker.tracker.MainActivity
import es.antonborri.home_widget.actionStartActivity

private val cellSize = 20.dp
private val cellSpacing = 4.dp
private val nameColumnWidth = 64.dp

/**
 * Shared Week/Month grid renderer (AC 2, 3, 6): one [StatusCell] per
 * `(date, goalId)` cell from the envelope, laid out goal-per-row /
 * date-per-column — the same `status-cell` grid vocabulary as in-app
 * Week/Month View. The cell/row count actually shown reflows to
 * [LocalSize]'s granted width/height (Glance [SizeMode.Responsive]); this
 * function never assumes one fixed cell count is always available.
 *
 * Story 5.3 (AC2, AC4): each [StatusCell] carries its own per-cell
 * `trackerapp://day` tap target — Glance supports per-composable click
 * actions with parameters, so per-cell deep-linking is achievable here.
 * Any remaining non-cell chrome (the goal-name column, the row/column
 * padding) falls back to [containerClick], which opens the containing
 * Week/Month View via the envelope's own `scope`/`rangeStart`.
 */
@Composable
fun WidgetGridContent(envelope: WidgetEnvelope?, emptyMessage: String) {
    if (envelope == null || envelope.isEmpty) {
        Text(text = emptyMessage, style = TextStyle(fontSize = 14.sp))
        return
    }

    val context = LocalContext.current
    val containerUri =
        if (envelope.scope == "month") {
            WidgetDeepLinks.month(envelope.rangeStart)
        } else {
            WidgetDeepLinks.week(envelope.rangeStart)
        }
    val containerClick = actionStartActivity<MainActivity>(context, containerUri)

    val size = LocalSize.current
    val perCell = cellSize + cellSpacing
    val maxColumns =
        ((size.width - nameColumnWidth) / perCell).toInt().coerceAtLeast(1)
    val maxRows = (size.height / (cellSize + cellSpacing)).toInt().coerceAtLeast(1)

    val dates = envelope.cells.map { it.date }.distinct().sorted()
    // Reflow rule: show the most recent dates/goals that fit the granted
    // size class rather than truncating from an assumed fixed grid.
    val visibleDates = dates.takeLast(maxColumns)

    val goalNames = LinkedHashMap<String, String>()
    for (cell in envelope.cells) goalNames.putIfAbsent(cell.goalId, cell.goalName)
    val visibleGoalIds = goalNames.keys.toList().take(maxRows)

    val cellsByGoalAndDate = envelope.cells.associateBy { it.goalId to it.date }

    Column(modifier = GlanceModifier.clickable(containerClick)) {
        for (goalId in visibleGoalIds) {
            Row(verticalAlignment = Alignment.Vertical.CenterVertically) {
                Text(
                    text = goalNames.getValue(goalId),
                    style = TextStyle(fontSize = 12.sp),
                    modifier = GlanceModifier.width(nameColumnWidth).clickable(containerClick),
                )
                for (date in visibleDates) {
                    val cell = cellsByGoalAndDate[goalId to date]
                    if (cell != null) {
                        StatusCell(
                            status = cell.status,
                            label = statusLabel(cell.goalName, cell.status, cell.date),
                            size = cellSize,
                            onClick = actionStartActivity<MainActivity>(context, WidgetDeepLinks.day(cell.date)),
                        )
                    } else {
                        // No cell for this (goal, date) — e.g. a paused date
                        // the bridge omitted entirely. Reserve its slot so
                        // the grid stays aligned, but render nothing.
                        androidx.glance.layout.Spacer(modifier = GlanceModifier.width(cellSize))
                    }
                    androidx.glance.layout.Spacer(modifier = GlanceModifier.width(cellSpacing))
                }
            }
        }
    }
}
