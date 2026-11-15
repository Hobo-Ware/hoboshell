import AppKit

final class DSBarSurface: NSView {
    private static let hairlineHeight: CGFloat = 1

    private let forcesSolid: Bool
    private let tint = NSView()
    private var observer: NSObjectProtocol?

    init(forcesSolid: Bool) {
        self.forcesSolid = forcesSolid
        super.init(frame: .zero)
        tint.wantsLayer = true
        DSPanelStyle.pin(tint, to: self)

        let hairline = NSView()
        hairline.wantsLayer = true
        hairline.layer?.backgroundColor = DSBarColor.hairline.cgColor
        hairline.translatesAutoresizingMaskIntoConstraints = false
        addSubview(hairline)
        NSLayoutConstraint.activate([
            hairline.leadingAnchor.constraint(equalTo: leadingAnchor),
            hairline.trailingAnchor.constraint(equalTo: trailingAnchor),
            hairline.topAnchor.constraint(equalTo: topAnchor),
            hairline.heightAnchor.constraint(equalToConstant: Self.hairlineHeight),
        ])

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
        let isSolid = forcesSolid || NSWorkspace.shared.accessibilityDisplayShouldReduceTransparency
        tint.layer?.backgroundColor = (isSolid ? DSBarColor.solid : DSBarColor.glass).cgColor
    }
}
