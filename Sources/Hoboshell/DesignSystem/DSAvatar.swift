import AppKit

final class DSAvatar: NSView {
    private let iconView: DSIconView

    var image: NSImage? {
        didSet { show(image) }
    }

    init(side: CGFloat, image: NSImage? = nil) {
        iconView = DSIconView(side: side)
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = side / 2
        layer?.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        DSPanelStyle.pin(iconView, to: self)
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: side),
            heightAnchor.constraint(equalToConstant: side),
        ])
        self.image = image
        show(image)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func show(_ image: NSImage?) {
        if let image {
            iconView.image = image
            iconView.contentTintColor = nil
        } else {
            iconView.image = DSIconSize.symbol("person.crop.circle.fill", description: "Account picture")
            iconView.contentTintColor = DSColor.dimText
        }
    }
}
