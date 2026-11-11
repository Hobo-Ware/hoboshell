import AppKit

final class PreviewCardView: DSControl {
    var onClose: (() -> Void)?

    private let preview = NSImageView()

    init(item: TaskbarItem, previewSize: CGSize) {
        super.init(frame: .zero)
        cornerRadius = DSRadius.card

        let title = DSLabel(item.title)
        title.setContentHuggingPriority(.defaultLow, for: .horizontal)
        title.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let header = NSStackView()
        header.orientation = .horizontal
        header.spacing = DSSpacing.s
        header.alignment = .centerY
        if let icon = item.icon {
            header.addArrangedSubview(DSIconView(side: DSIconSize.inline, image: icon))
        }
        header.addArrangedSubview(title)
        if item.close != nil {
            let closeButton = DSButton(symbol: "xmark", tip: "Close window", height: .compact)
            closeButton.onPress = { [weak self] in
                self?.onClose?()
            }
            header.addArrangedSubview(closeButton)
        }

        preview.image = DSIconSize.fit(item.icon, side: DSIconSize.grid)
        preview.imageScaling = .scaleProportionallyDown
        preview.translatesAutoresizingMaskIntoConstraints = false

        let column = NSStackView(views: [header, preview])
        column.orientation = .vertical
        column.spacing = DSSpacing.s
        column.translatesAutoresizingMaskIntoConstraints = false
        addSubview(column)
        NSLayoutConstraint.activate([
            preview.widthAnchor.constraint(equalToConstant: previewSize.width),
            preview.heightAnchor.constraint(equalToConstant: previewSize.height),
            header.widthAnchor.constraint(equalTo: column.widthAnchor),
            header.heightAnchor.constraint(greaterThanOrEqualToConstant: DSControlHeight.compact.value),
            column.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.m),
            column.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.m),
            column.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.m),
            column.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.m),
        ])
    }

    func show(preview image: NSImage) {
        preview.image = image
    }
}
