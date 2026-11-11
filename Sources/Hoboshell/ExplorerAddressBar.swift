import AppKit
import HoboshellCore

final class ExplorerAddressBar: NSView, NSTextFieldDelegate {
    private static let inset: CGFloat = 6
    private static let separatorWidth: CGFloat = 12
    private static let crumbPadding: CGFloat = 12
    private static let ellipsisWidth: CGFloat = 28
    private static let crumbHeight: CGFloat = 24

    var onNavigate: ((URL) -> Void)?
    var onSubmit: ((String) -> Void)?
    var onFinish: (() -> Void)?

    private let field = NSTextField()
    private let crumbs = NSView()
    private var segments: [BreadcrumbSegment] = []
    private var crumbButtons: [HoverButton] = []
    private var separators: [NSTextField] = []
    private let ellipsis = AddressBarButtons.make(title: "...")
    private(set) var isEditing = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 6
        layer?.backgroundColor = ExplorerTheme.fieldBackground
        layer?.borderColor = ExplorerTheme.fieldBorder
        layer?.borderWidth = 1
        field.isBordered = false
        field.drawsBackground = false
        field.focusRingType = .none
        field.font = .systemFont(ofSize: 13)
        field.lineBreakMode = .byTruncatingHead
        field.delegate = self
        field.isHidden = true
        ellipsis.target = self
        ellipsis.action = #selector(crumbClicked(_:))
        ellipsis.isHidden = true
        crumbs.addSubview(ellipsis)
        addSubview(crumbs)
        addSubview(field)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func show(_ folder: URL) {
        segments = Breadcrumbs.segments(for: folder)
        crumbButtons.forEach { $0.removeFromSuperview() }
        separators.forEach { $0.removeFromSuperview() }
        crumbButtons = segments.enumerated().map { index, segment in
            let button = AddressBarButtons.make(title: segment.name)
            button.tag = index
            button.target = self
            button.action = #selector(crumbClicked(_:))
            crumbs.addSubview(button)
            return button
        }
        separators = segments.dropFirst().map { _ in
            let label = NSTextField(labelWithString: ">")
            label.textColor = .tertiaryLabelColor
            label.font = .systemFont(ofSize: 11)
            label.alignment = .center
            crumbs.addSubview(label)
            return label
        }
        needsLayout = true
    }

    func beginEditing() {
        guard let url = segments.last?.url else { return }
        isEditing = true
        field.stringValue = url.path
        field.isHidden = false
        crumbs.isHidden = true
        window?.makeFirstResponder(field)
        field.currentEditor()?.selectAll(nil)
    }

    override func mouseDown(with event: NSEvent) {
        beginEditing()
    }

    override func layout() {
        super.layout()
        field.frame = NSRect(x: Self.inset + 4, y: (bounds.height - 20) / 2, width: bounds.width - 2 * Self.inset - 8, height: 20)
        crumbs.frame = bounds
        layoutCrumbs()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            let text = field.stringValue
            endEditing()
            onSubmit?(text)
            onFinish?()
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            endEditing()
            onFinish?()
            return true
        }
        return false
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        if isEditing {
            endEditing()
        }
    }

    @objc private func crumbClicked(_ sender: NSButton) {
        guard segments.indices.contains(sender.tag) else { return }
        onNavigate?(segments[sender.tag].url)
    }

    private func endEditing() {
        isEditing = false
        field.isHidden = true
        crumbs.isHidden = false
    }

    private func layoutCrumbs() {
        let widths = crumbButtons.map { $0.intrinsicContentSize.width + Self.crumbPadding }
        let available = bounds.width - 2 * Self.inset
        var used: CGFloat = 0
        var firstShown = crumbButtons.count
        for index in crumbButtons.indices.reversed() {
            let needed = widths[index] + (index > 0 ? Self.separatorWidth : 0)
            let reserve = index > 0 ? Self.ellipsisWidth : 0
            if used + needed + reserve > available && firstShown < crumbButtons.count { break }
            used += needed
            firstShown = index
        }
        let y = (bounds.height - Self.crumbHeight) / 2
        var x = Self.inset
        ellipsis.isHidden = firstShown == 0
        if firstShown > 0 {
            ellipsis.tag = firstShown - 1
            ellipsis.frame = NSRect(x: x, y: y, width: Self.ellipsisWidth, height: Self.crumbHeight)
            x += Self.ellipsisWidth
        }
        for index in crumbButtons.indices {
            let visible = index >= firstShown
            crumbButtons[index].isHidden = !visible
            if index > 0 { separators[index - 1].isHidden = !visible }
            guard visible else { continue }
            if index > 0 {
                separators[index - 1].frame = NSRect(x: x, y: y + 2, width: Self.separatorWidth, height: Self.crumbHeight - 6)
                x += Self.separatorWidth
            }
            crumbButtons[index].frame = NSRect(x: x, y: y, width: widths[index], height: Self.crumbHeight)
            x += widths[index]
        }
    }
}

private enum AddressBarButtons {
    static func make(title: String) -> HoverButton {
        let button = HoverButton(title: title, target: nil, action: nil)
        button.isBordered = false
        button.font = .systemFont(ofSize: 12)
        button.contentTintColor = .white
        button.wantsLayer = true
        button.layer?.cornerRadius = 4
        button.lineBreakMode = .byTruncatingTail
        return button
    }
}
