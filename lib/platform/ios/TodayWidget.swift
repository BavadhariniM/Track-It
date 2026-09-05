import SwiftUI
import WidgetKit

struct TodayEntry: TimelineEntry {
    let date: Date
    let envelope: WidgetEnvelope?
}

/// Reads only the already-computed `today_widget_data` envelope — never
/// calls into any evaluation logic (AC 6, AD-7).
struct TodayProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodayEntry {
        TodayEntry(date: Date(), envelope: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodayEntry) -> Void) {
        completion(TodayEntry(date: Date(), envelope: WidgetDataStore.readEnvelope(key: "today_widget_data")))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodayEntry>) -> Void) {
        let entry = TodayEntry(date: Date(), envelope: WidgetDataStore.readEnvelope(key: "today_widget_data"))
        // The app reloads this widget's timeline itself (home_widget's
        // WidgetCenter.reloadTimelines call, Story 5.1) whenever it
        // rewrites the shared container — this widget never re-derives its
        // own freshness or polls on a timer.
        completion(Timeline(entries: [entry], policy: .never))
    }
}

/// Today widget (AC 1, 4, 6): reduced-density rendering — each eligible
/// goal's name plus a status dot only, no progress bar, no fraction text
/// (UX-DR18). Story 5.3 (AC1, AC4): `.widgetURL` on the root view sets the
/// widget's single tap destination — `systemSmall` widgets support exactly
/// one tap destination for the whole widget, which matches AC1 exactly
/// (there is only one date to target, so whole-widget granularity is
/// correct here, not a limitation).
struct TodayWidgetEntryView: View {
    var entry: TodayProvider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if entry.envelope == nil || entry.envelope!.isEmpty {
                Text("No goals today").font(.caption)
            } else {
                ForEach(entry.envelope!.cells, id: \.goalId) { cell in
                    HStack(spacing: 8) {
                        StatusCellView(
                            status: cell.status,
                            label: StatusPresentationCatalog.label(goalName: cell.goalName, status: cell.status),
                            size: 16
                        )
                        Text(cell.goalName).font(.caption).lineLimit(1)
                    }
                }
            }
        }
        .padding()
        .widgetURL(entry.envelope.map { WidgetDeepLinks.day($0.generatedAt) })
    }
}

struct TodayWidget: Widget {
    let kind: String = "TodayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodayProvider()) { entry in
            TodayWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("Shows today's goal status at a glance.")
        .supportedFamilies([.systemSmall])
    }
}
