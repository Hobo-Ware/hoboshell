import AppKit

enum GalleryRow {
    private static let labelWidth: CGFloat = 150

    static func section(_ title: String, _ rows: [NSView]) -> NSView {
        let heading = DSLabel(title, style: .title, weight: .semibold)
        let stack = NSStackView(views: [heading, DSDivider()] + rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = DSSpacing.m
        if let divider = stack.arrangedSubviews.dropFirst().first {
            divider.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        return stack
    }

    static func make(_ title: String, _ samples: [(String, NSView)]) -> NSView {
        let name = DSLabel(title, style: .caption, color: DSColor.dimText)
        name.translatesAutoresizingMaskIntoConstraints = false
        name.widthAnchor.constraint(equalToConstant: labelWidth).isActive = true
        let columns = samples.map(column)
        let row = NSStackView(views: [name] + columns)
        row.orientation = .horizontal
        row.alignment = .top
        row.spacing = DSSpacing.l
        return row
    }

    static func states(_ title: String, _ build: () -> DSControl) -> NSView {
        make(title, DSControlState.allCases.map { state in
            let control = build()
            control.preview(state)
            return (state.title, control)
        })
    }

    private static func column(_ sample: (String, NSView)) -> NSView {
        let caption = DSLabel(sample.0, style: .caption, color: DSColor.dimText)
        let column = NSStackView(views: [sample.1, caption])
        column.orientation = .vertical
        column.alignment = .leading
        column.spacing = DSSpacing.xs
        return column
    }
}
