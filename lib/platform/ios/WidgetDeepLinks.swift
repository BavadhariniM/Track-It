import Foundation

/// The `trackerapp://` URI contract (Story 5.3) shared by both native
/// platforms and parsed by the Flutter side in
/// `lib/presentation/providers/widget_launch_router_provider.dart`. `date`
/// is always a naive ISO-8601 date-only string.
///
/// The `homeWidget` query item is required on iOS — `home_widget`'s iOS
/// plugin (`HomeWidgetPlugin.isWidgetUrl`) only intercepts
/// `application(_:open:)`/`scene(_:openURLContexts:)` calls whose URL
/// carries a query item literally named `homeWidget`; without it the tap is
/// silently dropped before Dart ever sees it. Android has no equivalent
/// requirement (its plugin keys off `Intent.action`, not URL shape), so
/// `WidgetDeepLinks.kt` omits it.
enum WidgetDeepLinks {
    static func day(_ date: String) -> URL {
        URL(string: "trackerapp://day?date=\(date)&homeWidget=true")!
    }

    static func week(_ date: String) -> URL {
        URL(string: "trackerapp://week?date=\(date)&homeWidget=true")!
    }

    static func month(_ date: String) -> URL {
        URL(string: "trackerapp://month?date=\(date)&homeWidget=true")!
    }
}
