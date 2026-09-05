package com.panda.tracker.tracker.widget

import android.content.Context
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.provideContent
import androidx.glance.currentState
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.fillMaxWidth
import androidx.glance.layout.padding
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import com.panda.tracker.tracker.MainActivity
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import es.antonborri.home_widget.HomeWidgetGlanceWidgetReceiver
import es.antonborri.home_widget.actionStartActivity

/**
 * Today widget (AC 1, 4, 6): reduced-density rendering — each eligible
 * goal's name plus a status dot only, no progress bars, no fraction text
 * (UX-DR18). Story 5.3 (AC1, AC4): a single click action on the whole
 * widget's root [Column] opens today's Day View — there is only one date to
 * target, so whole-widget granularity is correct here, not a limitation.
 * Reads only the already-computed `status` string from the decoded
 * envelope — no arithmetic, no comparison, no evaluation of any kind (AD-7).
 */
class TodayWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Single
    override val stateDefinition = HomeWidgetGlanceStateDefinition()

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent { Content(context, currentState()) }
    }

    @Composable
    private fun Content(context: Context, state: HomeWidgetGlanceState) {
        val envelope = parseWidgetEnvelope(state.preferences.getString("today_widget_data", null))

        var modifier = GlanceModifier.padding(12.dp)
        if (envelope != null) {
            modifier =
                modifier.clickable(
                    actionStartActivity<MainActivity>(context, WidgetDeepLinks.day(envelope.generatedAt))
                )
        }

        Column(modifier = modifier) {
            if (envelope == null || envelope.isEmpty) {
                Text(text = "No goals today", style = TextStyle(fontSize = 14.sp))
            } else {
                for (cell in envelope.cells) {
                    Row(
                        modifier = GlanceModifier.fillMaxWidth().padding(vertical = 4.dp),
                        verticalAlignment = Alignment.Vertical.CenterVertically,
                    ) {
                        StatusCell(
                            status = cell.status,
                            label = statusLabel(cell.goalName, cell.status),
                            size = 16.dp,
                        )
                        Text(
                            text = cell.goalName,
                            style = TextStyle(fontSize = 14.sp),
                            modifier = GlanceModifier.padding(start = 8.dp),
                        )
                    }
                }
            }
        }
    }
}

class TodayWidgetReceiver : HomeWidgetGlanceWidgetReceiver<TodayWidget>() {
    override val glanceAppWidget = TodayWidget()
}
