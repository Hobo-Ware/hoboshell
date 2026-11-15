import AppKit
import HoboshellCore

final class TrayFlyoutPanel: NSPanel {
    private static let gap = DSSpacing.s
    private static let margin = DSSpacing.s
    private static let travel: CGFloat = 28
    private static let riseCurve = CAMediaTimingFunction(controlPoints: 0, 0, 0, 1)

    let kind: TrayItemKind
    private let card: DSCard
    private var isSinking = false
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
        let length = DSMotion.duration(.rise)
        guard length > 0 else {
            orderFrontRegardless()
            return
        }
        let final = frame
        alphaValue = 0
        setFrame(final.offsetBy(dx: 0, dy: startOffset(for: final)), display: false)
        orderFrontRegardless()
        animate(to: final, alpha: 1, length: length)
    }

    func sink() {
        let length = DSMotion.duration(.rise)
        guard length > 0 else {
            orderOut(nil)
            return
        }
        isSinking = true
        let target = frame.offsetBy(dx: 0, dy: startOffset(for: frame))
        animate(to: target, alpha: 0, length: length) { [weak self] in
            self?.orderOut(nil)
        }
    }

    private func startOffset(for final: NSRect) -> CGFloat {
        guard let target = anchor() else { return 0 }
        return final.midY > target.frame.midY ? -Self.travel : Self.travel
    }

    private func animate(to frame: NSRect, alpha: CGFloat, length: TimeInterval, completion: (() -> Void)? = nil) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = length
            context.timingFunction = Self.riseCurve
            animator().setFrame(frame, display: true)
            animator().alphaValue = alpha
        }, completionHandler: completion)
    }

    func refit() {
        guard !isSinking, let target = anchor() else { return }
        card.layoutSubtreeIfNeeded()
        let size = card.fittingSize
        let origin = TrayFlyoutPlacement.origin(
            size: size, anchor: target.frame, screen: target.screen, gap: Self.gap, margin: Self.margin
        )
        setFrame(NSRect(origin: origin, size: size), display: true)
    }
}
