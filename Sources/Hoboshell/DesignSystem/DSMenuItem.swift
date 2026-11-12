import AppKit

final class DSMenuItem: NSMenuItem {
    private let handler: () -> Void

    init(
        _ title: String,
        symbol: String? = nil,
        state: NSControl.StateValue = .off,
        isEnabled: Bool = true,
        handler: @escaping () -> Void
    ) {
        self.handler = handler
        super.init(title: title, action: #selector(run), keyEquivalent: "")
        target = self
        self.state = state
        self.isEnabled = isEnabled
        image = symbol.flatMap { DSIconSize.symbol($0) }
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func run() {
        handler()
    }
}
