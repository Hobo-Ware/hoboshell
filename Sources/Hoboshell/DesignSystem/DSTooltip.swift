import AppKit
import HoboshellCore

final class DSTooltip {
    static let shared = DSTooltip()

    private static let gap = DSSpacing.xs
    private static let margin = DSSpacing.s

    private var timeline = TooltipTimeline<ObjectIdentifier>()
    private weak var current: DSControl?
    private var timer: Timer?
    private let panel = DSTooltipPanel()

    var isSuppressed: Bool {
        get { timeline.isSuppressed }
        set {
            timeline.isSuppressed = newValue
            if newValue { dismiss() }
        }
    }

    func pointerEntered(_ control: DSControl) {
        guard control.hasTip else { return }
        current = control
        run(timeline.apply(.entered(ObjectIdentifier(control))))
    }

    func pointerExited(_ control: DSControl) {
        run(timeline.apply(.exited(ObjectIdentifier(control))))
    }

    func dismiss() {
        run(timeline.apply(.dismissed))
    }

    func tipChanged(for control: DSControl) {
        guard panel.isVisible, control === current else { return }
        if control.hasTip {
            show(control)
        } else {
            dismiss()
        }
    }

    private func run(_ actions: [TooltipAction<ObjectIdentifier>]) {
        for action in actions {
            switch action {
            case .startTimer(let seconds):
                timer?.invalidate()
                timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
                    guard let self else { return }
                    self.run(self.timeline.apply(.timerFired))
                }
            case .cancelTimer:
                timer?.invalidate()
                timer = nil
            case .show(let target):
                guard let control = current, ObjectIdentifier(control) == target else {
                    dismiss()
                    return
                }
                show(control)
            case .hide:
                panel.orderOut(nil)
            }
        }
    }

    private func show(_ control: DSControl) {
        guard let text = control.tipText, let window = control.window, !control.visibleRect.isEmpty else {
            dismiss()
            return
        }
        let anchor = window.convertToScreen(control.convert(control.visibleRect, to: nil))
        guard let screen = window.screen?.frame ?? NSScreen.main?.frame else { return }
        let wasVisible = panel.isVisible
        panel.set(text: text)
        let size = panel.contentSize
        let origin = TooltipPlacement.origin(size: size, anchor: anchor, screen: screen, gap: Self.gap, margin: Self.margin)
        panel.setFrame(NSRect(origin: origin, size: size), display: true)
        guard !wasVisible else { return }
        panel.orderFrontRegardless()
        panel.fadeIn()
    }
}

private final class DSTooltipPanel: NSPanel {
    private let bubble = DSTooltipBubble()

    init() {
        super.init(contentRect: .zero, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: true)
        isFloatingPanel = true
        level = NSWindow.Level(rawValue: NSWindow.Level.popUpMenu.rawValue + 1)
        collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .fullScreenAuxiliary]
        appearance = NSAppearance(named: .darkAqua)
        hidesOnDeactivate = false
        isReleasedWhenClosed = false
        ignoresMouseEvents = true
        hasShadow = true
        isOpaque = false
        backgroundColor = .clear
        contentView = bubble
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    var contentSize: NSSize {
        bubble.layoutSubtreeIfNeeded()
        return bubble.fittingSize
    }

    func fadeIn() {
        DSMotion.appear(bubble)
    }

    func set(text: String) {
        bubble.text = text
    }
}
