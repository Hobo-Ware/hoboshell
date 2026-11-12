import AppKit
import HoboshellCore

final class PreviewCardPanel: NSPanel {
    private static let previewLimit = CGSize(width: 240, height: 150)
    private static let showDelay: TimeInterval = 0.3
    private static let hideDelay: TimeInterval = 0.25
    private static let gapAboveBar = DSSpacing.s
    private static let screenMargin = DSSpacing.s

    private var pendingShow: DispatchWorkItem?
    private var pendingHide: DispatchWorkItem?
    private var presentation = 0

    private(set) var ownerID: String?

    init() {
        super.init(contentRect: .zero, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: true)
        DSPanelStyle.apply(to: self, kind: .flyout)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func pointerEntered(owner: String, items: @escaping () -> [TaskbarItem], anchor: NSRect, screen: NSRect) {
        pendingHide?.cancel()
        pendingShow?.cancel()
        let show = DispatchWorkItem { [weak self] in
            self?.present(items(), owner: owner, anchor: anchor, screen: screen)
        }
        pendingShow = show
        DispatchQueue.main.asyncAfter(deadline: .now() + (isVisible ? 0 : Self.showDelay), execute: show)
    }

    func showNow(owner: String, items: [TaskbarItem], anchor: NSRect, screen: NSRect) {
        pendingHide?.cancel()
        pendingShow?.cancel()
        present(items, owner: owner, anchor: anchor, screen: screen)
    }

    func pointerLeft() {
        pendingShow?.cancel()
        pendingHide?.cancel()
        let hide = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        pendingHide = hide
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.hideDelay, execute: hide)
    }

    func dismiss() {
        pendingShow?.cancel()
        pendingHide?.cancel()
        hide()
    }

    private func hide() {
        ownerID = nil
        orderOut(nil)
    }

    private func present(_ items: [TaskbarItem], owner: String, anchor: NSRect, screen: NSRect) {
        guard !items.isEmpty, let background = contentView else { return }
        ownerID = owner
        presentation += 1
        let shown = presentation
        let isGroup = items.count > 1
        let cards = items.map { makeCard(for: $0, isGroup: isGroup) }
        background.subviews.forEach { $0.removeFromSuperview() }

        let size: NSSize
        if isGroup {
            let strip = PreviewCardStrip(cards: cards)
            DSPanelStyle.pin(strip, to: background)
            let content = strip.desiredSize
            size = NSSize(width: min(content.width, screen.width - 2 * Self.screenMargin), height: content.height)
        } else {
            DSPanelStyle.pin(cards[0], to: background)
            size = cards[0].fittingSize
        }
        let origin = PreviewCardLayout.origin(
            cardSize: size,
            anchor: anchor,
            screen: screen,
            gap: Self.gapAboveBar,
            margin: Self.screenMargin
        )
        setFrame(NSRect(origin: origin, size: size), display: true)
        orderFrontRegardless()

        WindowPreview.askForAccessOnce()
        for (item, card) in zip(items, cards) {
            if let id = item.windowID, let remembered = WindowPreview.cached(id) {
                card.show(preview: remembered)
            }
            item.preview?(Self.previewLimit) { [weak self, weak card] image in
                guard let self, self.presentation == shown, let image else { return }
                card?.show(preview: image)
            }
        }
    }

    private func makeCard(for item: TaskbarItem, isGroup: Bool) -> PreviewCardView {
        let card = PreviewCardView(item: item, previewSize: Self.previewLimit)
        card.onPress = { [weak self] in
            self?.dismiss()
            if isGroup, let reveal = item.reveal {
                reveal()
            } else {
                item.activate()
            }
        }
        card.onClose = { [weak self] in
            self?.dismiss()
            item.close?()
        }
        card.onHoverChange = { [weak self] isInside in
            if isInside {
                self?.pendingHide?.cancel()
            } else {
                self?.pointerLeft()
            }
        }
        return card
    }
}
