import AppKit

final class DSTextField: NSView, NSTextFieldDelegate {
    var onChange: ((String) -> Void)?
    var onSubmit: ((String) -> Void)?
    var onCancel: (() -> Void)?
    var onEndEditing: (() -> Void)?
    var onCommand: ((Selector) -> Bool)?

    var showsFocus: Bool {
        get { box.isFocused }
        set { box.isFocused = newValue }
    }

    var isEnabled = true {
        didSet {
            field.isEnabled = isEnabled
            alphaValue = isEnabled ? 1 : DSColor.disabledAlpha
        }
    }

    var stringValue: String {
        get { field.stringValue }
        set { field.stringValue = newValue }
    }

    let field = DSInputField()

    private let box = DSFieldBox()
    private let height: DSControlHeight

    init(
        placeholder: String = "",
        height: DSControlHeight = .regular,
        leading: NSView? = nil,
        trailing: NSView? = nil,
        radius: CGFloat = DSRadius.control
    ) {
        self.height = height
        super.init(frame: .zero)
        box.radius = radius
        let font = height.textStyle.font()
        field.font = font
        field.textColor = DSColor.text
        field.placeholderAttributedString = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: DSColor.dimText, .font: font]
        )
        field.delegate = self
        field.onFocusChange = { [weak self] isFocused in
            self?.box.isFocused = isFocused
        }
        field.setContentHuggingPriority(.defaultLow, for: .horizontal)
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        let row = NSStackView(views: [leading, field, trailing].compactMap { $0 })
        row.orientation = .horizontal
        row.spacing = DSSpacing.xs
        row.alignment = .centerY
        for view in [box, row] {
            view.translatesAutoresizingMaskIntoConstraints = false
            addSubview(view)
        }
        NSLayoutConstraint.activate([
            box.leadingAnchor.constraint(equalTo: leadingAnchor),
            box.trailingAnchor.constraint(equalTo: trailingAnchor),
            box.topAnchor.constraint(equalTo: topAnchor),
            box.bottomAnchor.constraint(equalTo: bottomAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: height.value)
    }

    override func mouseDown(with event: NSEvent) {
        focus()
    }

    func focus() {
        window?.makeFirstResponder(field)
    }

    func controlTextDidChange(_ notification: Notification) {
        onChange?(field.stringValue)
    }

    func controlTextDidEndEditing(_ notification: Notification) {
        onEndEditing?()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if onCommand?(commandSelector) == true {
            return true
        }
        if commandSelector == #selector(NSResponder.insertNewline(_:)), let onSubmit {
            onSubmit(field.stringValue)
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)), let onCancel {
            onCancel()
            return true
        }
        return false
    }
}

final class DSInputField: NSTextField {
    var onFocusChange: ((Bool) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isBordered = false
        drawsBackground = false
        focusRingType = .none
        lineBreakMode = .byTruncatingTail
        cell?.usesSingleLineMode = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func becomeFirstResponder() -> Bool {
        let accepted = super.becomeFirstResponder()
        if accepted {
            onFocusChange?(true)
        }
        return accepted
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        onFocusChange?(false)
    }
}
