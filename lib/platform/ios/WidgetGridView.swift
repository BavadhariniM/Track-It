import SwiftUI

/// Shared Week/Month grid renderer (AC 2, 3, 6): one [StatusCellView] per
/// `(date, goalId)` cell, laid out goal-per-row / date-per-column — the
/// same `status-cell` grid vocabulary as in-app Week/Month View. Uses
/// `GeometryReader` so the visible cell/row count reflows to whatever size
/// the widget family's actual frame grants; this view never hard-codes one
/// fixed grid size for all families.
///
/// Story 5.3 (AC2, AC4): each cell wraps its own `Link` to
/// `trackerapp://day` — WidgetKit supports multiple independent `Link` tap
/// targets within one medium/large widget, so per-cell deep-linking is
/// achievable here. The goal-name column (the remaining non-cell chrome)
/// gets its own `Link` to the containing Week/Month View, derived from the
/// envelope's own `scope`/`rangeStart`.
struct WidgetGridView: View {
    let envelope: WidgetEnvelope?
    let emptyMessage: String

    private let cellSize: CGFloat = 20
    private let cellSpacing: CGFloat = 4
    private let nameColumnWidth: CGFloat = 64

    var body: some View {
        if envelope == nil || envelope!.isEmpty {
            Text(emptyMessage).font(.caption)
        } else {
            GeometryReader { geometry in
                let cells = envelope!.cells
                let containerURL: URL =
                    envelope!.scope == "month"
                        ? WidgetDeepLinks.month(envelope!.rangeStart)
                        : WidgetDeepLinks.week(envelope!.rangeStart)
                let perCell = cellSize + cellSpacing
                let maxColumns = max(1, Int((geometry.size.width - nameColumnWidth) / perCell))
                let maxRows = max(1, Int(geometry.size.height / perCell))

                // Reflow rule: show the most recent dates/goals that fit
                // the granted family size rather than truncating from an
                // assumed fixed grid.
                let dates = Array(Set(cells.map(\.date))).sorted()
                let visibleDates = Array(dates.suffix(maxColumns))

                let goalOrder = orderedGoalIds(cells)
                let visibleGoalIds = Array(goalOrder.prefix(maxRows))
                let goalNames = Dictionary(cells.map { ($0.goalId, $0.goalName) }, uniquingKeysWith: { first, _ in first })
                let cellLookup = Dictionary(
                    cells.map { ("\($0.goalId)|\($0.date)", $0) },
                    uniquingKeysWith: { first, _ in first }
                )

                VStack(alignment: .leading, spacing: cellSpacing) {
                    ForEach(visibleGoalIds, id: \.self) { goalId in
                        HStack(spacing: cellSpacing) {
                            Link(destination: containerURL) {
                                Text(goalNames[goalId] ?? "")
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .frame(width: nameColumnWidth, alignment: .leading)
                            }
                            ForEach(visibleDates, id: \.self) { date in
                                if let cell = cellLookup["\(goalId)|\(date)"] {
                                    Link(destination: WidgetDeepLinks.day(cell.date)) {
                                        StatusCellView(
                                            status: cell.status,
                                            label: StatusPresentationCatalog.label(
                                                goalName: cell.goalName,
                                                status: cell.status,
                                                date: cell.date
                                            ),
                                            size: cellSize
                                        )
                                    }
                                } else {
                                    // No cell for this (goal, date) — e.g. a
                                    // paused date the bridge omitted
                                    // entirely. Reserve its slot so the
                                    // grid stays aligned.
                                    Color.clear.frame(width: cellSize, height: cellSize)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func orderedGoalIds(_ cells: [WidgetCell]) -> [String] {
        var order: [String] = []
        var seen = Set<String>()
        for cell in cells where !seen.contains(cell.goalId) {
            seen.insert(cell.goalId)
            order.append(cell.goalId)
        }
        return order
    }
}
