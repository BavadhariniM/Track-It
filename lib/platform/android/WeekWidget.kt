package com.panda.tracker.tracker.widget

import android.content.Context
import androidx.compose.ui.unit.DpSize
import androidx.compose.ui.unit.dp
import androidx.glance.GlanceId
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver

/**
 * Week widget (AC 2, 4, 6): the same `status-cell` grid vocabulary as
 * in-app Week View, sized to whatever cell count the platform's granted
 * widget size class allows (UX-DR18) — [SizeMode.Responsive] across the
 * medium/large size range declared in `week_widget_info.xml`.
 */
class WeekWidget : GlanceAppWidget() {
    override val sizeMode =
        SizeMode.Responsive(
            setOf(
                DpSize(180.dp, 110.dp),
                DpSize(270.dp, 110.dp),
                DpSize(270.dp, 180.dp),
                DpSize(360.dp, 180.dp),
            )
        )
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val envelope =
                parseWidgetEnvelope(
                    currentState<HomeWidgetGlanceState>().preferences.getString("week_widget_data", null)
                )
            WidgetGridContent(envelope, emptyMessage = "No goals this week")
        }
    }
}

class WeekWidgetReceiver : HomeWidgetGlanceWidgetReceiver<WeekWidget>() {
    override val glanceAppWidget = WeekWidget()
}
