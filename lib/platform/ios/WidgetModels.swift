import Foundation

/// One `(date, goalId)` cell from Story 5.1's shared-container envelope.
struct WidgetCell: Codable {
    let date: String
    let goalId: String
    let goalName: String
    let status: String
}

/// The JSON envelope shape fixed by Story 5.1 — mirrors it exactly, do not
/// diverge from it.
struct WidgetEnvelope: Codable {
    let scope: String
    let generatedAt: String
    let rangeStart: String
    let rangeEnd: String
    let isEmpty: Bool
    let cells: [WidgetCell]
}

/// Reads and decodes the raw JSON string `home_widget` deposited in the App
/// Group's `UserDefaults` suite (configured in Story 5.1 Task 6). Pure
/// parsing only — no widget in this file ever derives a status, count, or
/// comparison from raw values (AD-7's cache-only rule, restated for native
/// code).
enum WidgetDataStore {
    static let appGroupId = "group.com.panda.tracker.tracker"

    static func readEnvelope(key: String) -> WidgetEnvelope? {
        guard
            let defaults = UserDefaults(suiteName: appGroupId),
            let json = defaults.string(forKey: key),
            let data = json.data(using: .utf8)
        else { return nil }
        return try? JSONDecoder().decode(WidgetEnvelope.self, from: data)
    }
}
