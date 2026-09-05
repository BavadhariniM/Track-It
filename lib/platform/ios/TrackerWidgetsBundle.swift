import WidgetKit
import SwiftUI

/// Entry point for the WidgetKit extension target this story adds (Task
/// 3.1). Bundles all three home-screen widgets — only `systemSmall`/
/// `systemMedium`/`systemLarge` families are configured across them; no
/// Lock Screen/StandBy accessory family is added (FR-31).
@main
struct TrackerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        WeekWidget()
        MonthWidget()
    }
}
