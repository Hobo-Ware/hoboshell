import AppKit
import HoboshellCore

final class PreviewCardPanel: NSPanel {
    private static let previewLimit = CGSize(width: 240, height: 150)
    private static let showDelay: TimeInterval = 0.4
    private static let hideDelay: TimeInterval = 0.25
    private static let gapAboveBar = DSSpacing.s
    private static let screenMargin = DSSpacing.s

    private var pendingShow: DispatchWorkItem?
    private var pendingHide: DispatchWorkItem?
    private var presentation = 0

    init() {
        super.init(contentRect: .zero, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: true)
        DSPanelStyle.apply(to: self, kind: .flyout)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func pointerEntered(_ item: TaskbarItem, anchor: NSRect, screen: NSRect) {
        pendingHide?.cancel()
        pendingShow?.cancel()
        let show = DispatchWorkItem { [weak self] in
            self?.present(item, anchor: anchor, screen: screen)
        }
        pendingShow = show
        DispatchQueue.main.asyncAfter(deadline: .now() + (isVisible ? 0 : Self.showDelay), execute: show)
    }

    func pointerLeft() {
        pendingShow?.cancel()
        pendingHide?.cancel()
        let hide = DispatchWorkItem { [weak self] in
            self?.orderOut(nil)
        }
        pendingHide = hide
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.hideDelay, execute: hide)
    }

    func dismiss() {
        pendingShow?.cancel()
        pendingHide?.cancel()
        orderOut(nil)
    }

    private func present(_ item: TaskbarItem, anchor: NSRect, screen: NSRect) {
        presentation += 1
        let shown = presentation
        let card = PreviewCardView(item: item, previewSize: Self.previewLimit)
        card.onPress = { [weak self] in
            self?.dismiss()
            item.activate()
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
        guard let background = contentView else { return }
        background.subviews.forEach { $0.removeFromSuperview() }
        DSPanelStyle.pin(card, to: background)

        let size = card.fittingSize
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
        item.preview?(Self.previewLimit) { [weak self, weak card] image in
            guard let self, self.presentation == shown, let image else { return }
            card?.show(preview: image)
        }
    }
}
