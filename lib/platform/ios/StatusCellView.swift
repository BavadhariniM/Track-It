import SwiftUI

/// The shared `status-cell` unit rendered by all three widgets: a rounded
/// rectangle with `6pt` corner radius (`rounded.sm`), a status-colored
/// fill, a centered glyph, and an accessibility label — the identical
/// color+glyph+label vocabulary as in-app (UX-DR6/UX-DR18), no widget-only
/// color treatment.
struct StatusCellView: View {
    let status: String
    let label: String
    var size: CGFloat = 24

    var body: some View {
        let presentation = StatusPresentationCatalog.presentation(for: status)
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(presentation.backgroundColorName))
            .frame(width: size, height: size)
            .overlay(
                Text(presentation.glyph)
                    .font(.system(size: size / 2, weight: .bold))
                    .foregroundColor(Color(presentation.onColorName))
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }
}
