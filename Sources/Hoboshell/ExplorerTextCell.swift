import AppKit

final class ExplorerTextCell: NSTableCellView {
    static let identifier = NSUserInterfaceItemIdentifier("ExplorerTextCell")

    private let label = DSLabel(color: DSColor.dimText)
    private lazy var trailing = label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        identifier = Self.identifier
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        textField = label
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            trailing,
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(_ text: String, alignment: NSTextAlignment) {
        label.stringValue = text
        label.alignment = alignment
        trailing.constant = alignment == .right ? -DSSpacing.m : -DSSpacing.s
    }
}
