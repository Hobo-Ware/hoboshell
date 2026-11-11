import AppKit

final class DSGridCell: DSControl {
    static let size = NSSize(width: 96, height: 96)

    var onSelect: (() -> Void)?
    var onOpen: (() -> Void)?

    let label: NSTextField

    private let iconView = DSIconView(side: DSIconSize.grid)

    init(label: NSTextField? = nil) {
        self.label = label ?? DSLabel()
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        cornerRadius = DSRadius.card

        self.label.font = DSTextStyle.caption.font()
        self.label.textColor = DSColor.text
        self.label.alignment = .center
        self.label.maximumNumberOfLines = 2
        self.label.lineBreakMode = .byTruncatingMiddle
        self.label.cell?.wraps = true
        self.label.cell?.truncatesLastVisibleLine = true
        self.label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconView)
        addSubview(self.label)
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.s),
            iconView.centerXAnchor.constraint(equalTo: centerXAnchor),
            self.label.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: DSSpacing.xs),
            self.label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.xxs),
            self.label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.xxs),
            self.label.heightAnchor.constraint(equalToConstant: DSTextStyle.caption.lineHeight * 2),
        ])
    }

    func show(name: String, icon: NSImage) {
        label.stringValue = name
        iconView.image = icon
        setAccessibilityLabel(name)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        if label.isEditable, label.frame.contains(local) {
            return label
        }
        return super.hitTest(point)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard handlesClicks else { return }
        onSelect?()
        if event.clickCount == 2 {
            onOpen?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        if handlesClicks {
            onSelect?()
        }
        super.rightMouseDown(with: event)
    }
}
