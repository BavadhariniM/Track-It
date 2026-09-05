package com.panda.tracker.tracker.widget

import android.net.Uri

/**
 * The `trackerapp://` URI contract (Story 5.3) shared by both native
 * platforms and parsed by the Flutter side in
 * `lib/presentation/providers/widget_launch_router_provider.dart`. `date`
 * is always a naive ISO-8601 date-only string.
 */
object WidgetDeepLinks {
    fun day(date: String): Uri = Uri.parse("trackerapp://day?date=$date")

    fun week(date: String): Uri = Uri.parse("trackerapp://week?date=$date")

    fun month(date: String): Uri = Uri.parse("trackerapp://month?date=$date")
}
