import AppKit

final class TaskbarItemView: NSView {
    private static let sidePadding: CGFloat = 10
    private static let iconToTitleGap: CGFloat = 8

    private let onClick: () -> Void

    init(icon: NSImage?, title: String?, isActive: Bool, size: NSSize, onClick: @escaping () -> Void) {
        self.onClick = onClick
        super.init(frame: NSRect(origin: .zero, size: size))
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.backgroundColor = isActive ? ShellButton.activeBackground : nil
        translatesAutoresizingMaskIntoConstraints = false

        let content = NSStackView()
        content.orientation = .horizontal
        content.spacing = Self.iconToTitleGap
        content.translatesAutoresizingMaskIntoConstraints = false
        if let icon {
            content.addArrangedSubview(NSImageView(image: icon))
        }
        if let title {
            let label = NSTextField(labelWithString: title)
            label.font = .systemFont(ofSize: 12)
            label.lineBreakMode = .byTruncatingTail
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            content.addArrangedSubview(label)
        }
        addSubview(content)

        var constraints = [
            widthAnchor.constraint(equalToConstant: size.width),
            heightAnchor.constraint(equalToConstant: size.height),
            content.centerYAnchor.constraint(equalTo: centerYAnchor),
        ]
        if title == nil {
            constraints.append(content.centerXAnchor.constraint(equalTo: centerXAnchor))
        } else {
            constraints.append(content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Self.sidePadding))
            constraints.append(content.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -Self.sidePadding))
        }
        NSLayoutConstraint.activate(constraints)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        super.hitTest(point) == nil ? nil : self
    }

    override func mouseUp(with event: NSEvent) {
        if bounds.contains(convert(event.locationInWindow, from: nil)) {
            onClick()
        }
    }
}
