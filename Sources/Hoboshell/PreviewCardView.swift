import AppKit

final class PreviewCardView: NSView {
    private static let padding: CGFloat = 10
    private static let headerIconSide: CGFloat = 16
    private static let placeholderIconSide: CGFloat = 64
    private static let closeButtonSide: CGFloat = 22

    var onActivate: (() -> Void)?
    var onClose: (() -> Void)?
    var onHoverChange: ((Bool) -> Void)?

    private let preview = NSImageView()

    init(item: TaskbarItem, previewSize: CGSize) {
        super.init(frame: .zero)

        let title = NSTextField(labelWithString: item.title)
        title.font = .systemFont(ofSize: 12)
        title.lineBreakMode = .byTruncatingTail
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let header = NSStackView()
        header.orientation = .horizontal
        header.spacing = 6
        if let icon = ShellButton.icon(item.icon, side: Self.headerIconSide) {
            header.addArrangedSubview(NSImageView(image: icon))
        }
        header.addArrangedSubview(title)
        header.addArrangedSubview(NSView())
        if item.close != nil {
            let closeButton = ShellButton.make(
                title: "✕",
                size: NSSize(width: Self.closeButtonSide, height: Self.closeButtonSide),
                fontSize: 11,
                target: self,
                action: #selector(closePressed)
            )
            closeButton.toolTip = "Close window"
            header.addArrangedSubview(closeButton)
        }

        preview.image = ShellButton.icon(item.icon, side: Self.placeholderIconSide)
        preview.imageScaling = .scaleProportionallyDown
        preview.translatesAutoresizingMaskIntoConstraints = false

        let column = NSStackView(views: [header, preview])
        column.orientation = .vertical
        column.spacing = 8
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)
        NSLayoutConstraint.activate([
            preview.widthAnchor.constraint(equalToConstant: previewSize.width),
            preview.heightAnchor.constraint(equalToConstant: previewSize.height),
            header.widthAnchor.constraint(equalTo: column.widthAnchor),
            header.heightAnchor.constraint(equalToConstant: Self.closeButtonSide),
            column.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.padding),
            column.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Self.padding),
            column.topAnchor.constraint(equalTo: topAnchor, constant: Self.padding),
            column.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Self.padding),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(preview image: NSImage) {
        preview.image = image
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        HoverTracking.install(on: self)
    }

    override func mouseEntered(with event: NSEvent) {
        onHoverChange?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHoverChange?(false)
    }

    override func mouseUp(with event: NSEvent) {
        if bounds.contains(convert(event.locationInWindow, from: nil)) {
            onActivate?()
        }
    }

    @objc private func closePressed() {
        onClose?()
    }
}
