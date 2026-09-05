import SwiftUI
import WidgetKit

struct MonthEntry: TimelineEntry {
    let date: Date
    let envelope: WidgetEnvelope?
}

struct MonthProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthEntry {
        MonthEntry(date: Date(), envelope: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthEntry) -> Void) {
        completion(MonthEntry(date: Date(), envelope: WidgetDataStore.readEnvelope(key: "month_widget_data")))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthEntry>) -> Void) {
        let entry = MonthEntry(date: Date(), envelope: WidgetDataStore.readEnvelope(key: "month_widget_data"))
        completion(Timeline(entries: [entry], policy: .never))
    }
}

/// Month widget (AC 3, 4, 6): the same `status-cell` grid vocabulary as
/// in-app Month View, at the platform's supported density. Only home-screen
/// families are supported — `systemLarge` here, never a Lock
/// Screen/StandBy accessory family (FR-31).
struct MonthWidgetEntryView: View {
    var entry: MonthProvider.Entry

    var body: some View {
        WidgetGridView(envelope: entry.envelope, emptyMessage: "No goals this month")
            .padding()
    }
}

struct MonthWidget: Widget {
    let kind: String = "MonthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthProvider()) { entry in
            MonthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Month")
        .description("Shows this month's goal status grid.")
        .supportedFamilies([.systemLarge])
    }
}
