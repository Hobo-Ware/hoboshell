import AppKit

final class TrayFlyoutContext {
    weak var panel: TrayFlyoutPanel?
    let dismiss: () -> Void

    init(dismiss: @escaping () -> Void) {
        self.dismiss = dismiss
    }

    func refit() {
        panel?.refit()
    }
}

enum TrayFlyoutStack {
    static func make(_ rows: [NSView], spacing: CGFloat = DSSpacing.xxs) -> NSStackView {
        let stack = NSStackView(views: rows)
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = spacing
        for row in rows {
            row.widthAnchor.constraint(equalTo: stack.widthAnchor).isActive = true
        }
        return stack
    }
}
