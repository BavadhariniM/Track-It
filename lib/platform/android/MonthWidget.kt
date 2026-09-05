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
 * Month widget (AC 3, 4, 6): the same `status-cell` grid vocabulary as
 * in-app Month View, at the platform's supported density —
 * [SizeMode.Responsive] across the large size range declared in
 * `month_widget_info.xml`.
 */
class MonthWidget : GlanceAppWidget() {
    override val sizeMode =
        SizeMode.Responsive(
            setOf(
                DpSize(270.dp, 180.dp),
                DpSize(360.dp, 180.dp),
                DpSize(360.dp, 270.dp),
                DpSize(450.dp, 270.dp),
            )
        )
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val envelope =
                parseWidgetEnvelope(
                    currentState<HomeWidgetGlanceState>().preferences.getString("month_widget_data", null)
                )
            WidgetGridContent(envelope, emptyMessage = "No goals this month")
        }
    }
}

class MonthWidgetReceiver : HomeWidgetGlanceWidgetReceiver<MonthWidget>() {
    override val glanceAppWidget = MonthWidget()
}
