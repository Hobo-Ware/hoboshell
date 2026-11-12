import AppKit
import HoboshellCore

final class TrayFlyoutPanel: NSPanel {
    private static let gap = DSSpacing.s
    private static let margin = DSSpacing.s

    let kind: TrayItemKind
    private let card: DSCard
    private let anchor: () -> (frame: NSRect, screen: NSRect)?

    init(kind: TrayItemKind, content: NSView, width: CGFloat, anchor: @escaping () -> (frame: NSRect, screen: NSRect)?) {
        self.kind = kind
        self.anchor = anchor
        card = DSCard(radius: DSRadius.card)
        super.init(contentRect: .zero, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: true)
        DSPanelStyle.apply(to: self, kind: .flyout)
        contentView = card
        content.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(content)
        NSLayoutConstraint.activate([
            content.widthAnchor.constraint(equalToConstant: width),
            content.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: DSSpacing.s),
            content.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -DSSpacing.s),
            content.topAnchor.constraint(equalTo: card.topAnchor, constant: DSSpacing.s),
            content.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -DSSpacing.s),
        ])
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func present() {
        refit()
        orderFrontRegardless()
    }

    func refit() {
        guard let target = anchor() else { return }
        card.layoutSubtreeIfNeeded()
        let size = card.fittingSize
        let origin = TrayFlyoutPlacement.origin(
            size: size, anchor: target.frame, screen: target.screen, gap: Self.gap, margin: Self.margin
        )
        setFrame(NSRect(origin: origin, size: size), display: true)
    }
}
