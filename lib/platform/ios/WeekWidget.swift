import SwiftUI
import WidgetKit

struct WeekEntry: TimelineEntry {
    let date: Date
    let envelope: WidgetEnvelope?
}

struct WeekProvider: TimelineProvider {
    func placeholder(in context: Context) -> WeekEntry {
        WeekEntry(date: Date(), envelope: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (WeekEntry) -> Void) {
        completion(WeekEntry(date: Date(), envelope: WidgetDataStore.readEnvelope(key: "week_widget_data")))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WeekEntry>) -> Void) {
        let entry = WeekEntry(date: Date(), envelope: WidgetDataStore.readEnvelope(key: "week_widget_data"))
        completion(Timeline(entries: [entry], policy: .never))
    }
}

/// Week widget (AC 2, 4, 6): the same `status-cell` grid vocabulary as
/// in-app Week View, sized to whatever the granted widget family allows
/// (UX-DR18).
struct WeekWidgetEntryView: View {
    var entry: WeekProvider.Entry

    var body: some View {
        WidgetGridView(envelope: entry.envelope, emptyMessage: "No goals this week")
            .padding()
    }
}

struct WeekWidget: Widget {
    let kind: String = "WeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WeekProvider()) { entry in
            WeekWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Week")
        .description("Shows this week's goal status grid.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
