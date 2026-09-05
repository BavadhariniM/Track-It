package com.panda.tracker.tracker.widget

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.background
import androidx.glance.appwidget.cornerRadius
import androidx.glance.layout.Alignment
import androidx.glance.layout.Box
import androidx.glance.layout.size
import androidx.glance.semantics.contentDescription
import androidx.glance.semantics.semantics
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextAlign
import androidx.glance.text.TextStyle
import androidx.glance.unit.ColorProvider

/**
 * The shared `status-cell` unit rendered by all three widgets: a fixed-size
 * square, `6dp` corner radius (`rounded.sm`), a status-colored background, a
 * centered glyph, and a semantics [label] — the identical color+glyph+label
 * vocabulary as in-app (UX-DR6/UX-DR18), no widget-only color treatment. An
 * optional [onClick] (Story 5.3) makes the cell its own tap target; when
 * `null` the cell renders exactly as before (Stories 5.1/5.2's read-only
 * behavior, e.g. the negative-gesture guarantee of AC3).
 */
@Composable
fun StatusCell(status: String, label: String, size: Dp = 24.dp, onClick: Action? = null) {
    val presentation = presentationFor(status)
    var modifier =
        GlanceModifier.size(size)
            .cornerRadius(6.dp)
            .background(ColorProvider(presentation.backgroundColorRes))
            .semantics { contentDescription = label }
    if (onClick != null) {
        modifier = modifier.clickable(onClick)
    }
    Box(
        modifier = modifier,
        contentAlignment = Alignment.Center,
    ) {
        Text(
            text = presentation.glyph,
            style =
                TextStyle(
                    color = ColorProvider(presentation.onColorRes),
                    fontSize = (size.value / 2).sp,
                    fontWeight = FontWeight.Bold,
                    textAlign = TextAlign.Center,
                ),
        )
    }
}
