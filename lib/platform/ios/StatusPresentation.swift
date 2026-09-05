import SwiftUI

/// The exact color/glyph/label vocabulary from `DESIGN.md`'s color tokens
/// (Story 5.2 Dev Notes table). Every widget cell's color/glyph/label is a
/// direct lookup from this table on the `status` string already present in
/// the decoded JSON — no arithmetic, no comparison, no re-implementation of
/// any evaluation concept (AD-7). Colors reference Asset Catalog color sets
/// (Any/Dark appearance variants) so both platforms encode the identical
/// hex values verbatim, light and dark, per Task 4.1's parity guardrail.
struct StatusPresentation {
    let backgroundColorName: String
    let onColorName: String
    let glyph: String
    let labelWord: String
}

enum StatusPresentationCatalog {
    static let presentations: [String: StatusPresentation] = [
        "success": StatusPresentation(
            backgroundColorName: "StatusSuccessBg",
            onColorName: "StatusSuccessOn",
            glyph: "✓",
            labelWord: "Success"
        ),
        "fail": StatusPresentation(
            backgroundColorName: "StatusFailBg",
            onColorName: "StatusFailOn",
            glyph: "✕",
            labelWord: "Failed"
        ),
        "cheat": StatusPresentation(
            backgroundColorName: "StatusCheatBg",
            onColorName: "StatusCheatOn",
            glyph: "C",
            labelWord: "Cheat day used"
        ),
        "pending": StatusPresentation(
            backgroundColorName: "StatusPendingBg",
            onColorName: "StatusPendingOn",
            glyph: "…",
            labelWord: "Pending"
        ),
        "empty": StatusPresentation(
            backgroundColorName: "StatusEmptyBg",
            onColorName: "StatusEmptyOn",
            glyph: "–",
            labelWord: "Not scheduled"
        ),
    ]

    static func presentation(for status: String) -> StatusPresentation {
        presentations[status] ?? presentations["empty"]!
    }

    /// "<goal>, <state>" for the Today widget's per-goal dot; "<goal>,
    /// <date>, <state>" for Week/Month grid cells, matching EXPERIENCE.md's
    /// Accessibility Floor pattern.
    static func label(goalName: String, status: String, date: String? = nil) -> String {
        let word = presentation(for: status).labelWord
        if let date {
            return "\(goalName), \(date), \(word)"
        }
        return "\(goalName), \(word)"
    }
}
