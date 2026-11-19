import AppKit
import HoboshellCore

final class DSGlassCard: NSView {
    private let glass = DSGlass.makeBackdrop(cornerRadius: DSRadius.card)
    private let fallback = DSCard()
    private var observer: NSObjectProtocol?

    init() {
        super.init(frame: .zero)
        DSPanelStyle.pin(fallback, to: self)
        DSPanelStyle.pin(glass, to: self)
        refresh()
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        if let observer {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    private func refresh() {
        let kind = BarSurfaceKind.pick(
            forcesSolid: false,
            reducesTransparency: NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency,
            hasSystemGlass: DSGlass.isAvailable
        )
        glass.isHidden = kind != .systemGlass
        fallback.isHidden = kind == .systemGlass
    }
}
