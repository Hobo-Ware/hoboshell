import AppKit

final class ExplorerNameCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("ExplorerNameCell")

    let nameField = ExplorerNameField(labelWithString: "")
    private let iconView = DSIconView(side: DSIconSize.toolbar)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.identifier
        nameField.font = DSTextStyle.body.font()
        nameField.textColor = DSColor.text
        nameField.lineBreakMode = .byTruncatingTail
        nameField.cell?.usesSingleLineMode = true
        nameField.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        addSubview(nameField)
        imageView = iconView
        textField = nameField
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            nameField.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: DSSpacing.s),
            nameField.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
            nameField.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(name: String, icon: NSImage) {
        nameField.stringValue = name
        iconView.image = icon
    }
}
