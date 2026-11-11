import AppKit

final class DSSearchField: NSView {
    var onChange: ((String) -> Void)?
    var onSubmit: ((String) -> Void)?
    var onCancel: (() -> Void)?

    var onCommand: ((Selector) -> Bool)? {
        get { input.onCommand }
        set { input.onCommand = newValue }
    }

    var stringValue: String {
        get { input.stringValue }
        set {
            input.stringValue = newValue
            showClearButton()
        }
    }

    var isEnabled: Bool {
        get { input.isEnabled }
        set { input.isEnabled = newValue }
    }

    var showsFocus: Bool {
        get { input.showsFocus }
        set { input.showsFocus = newValue }
    }

    var field: NSTextField {
        input.field
    }

    private let input: DSTextField
    private let clearButton: DSButton

    init(placeholder: String = "Search", height: DSControlHeight = .regular) {
        clearButton = DSButton(symbol: "xmark.circle.fill", tip: "Clear", height: .compact)
        let icon = DSIconView(
            side: DSIconSize.inline,
            image: DSIconSize.symbol("magnifyingglass", description: "Search"),
            tint: DSColor.dimText
        )
        input = DSTextField(placeholder: placeholder, height: height, leading: icon, trailing: clearButton)
        super.init(frame: .zero)
        input.translatesAutoresizingMaskIntoConstraints = false
        addSubview(input)
        NSLayoutConstraint.activate([
            input.leadingAnchor.constraint(equalTo: leadingAnchor),
            input.trailingAnchor.constraint(equalTo: trailingAnchor),
            input.topAnchor.constraint(equalTo: topAnchor),
            input.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        input.onChange = { [weak self] text in
            self?.showClearButton()
            self?.onChange?(text)
        }
        input.onSubmit = { [weak self] text in
            self?.onSubmit?(text)
        }
        input.onCancel = { [weak self] in
            self?.cancel()
        }
        clearButton.onPress = { [weak self] in
            self?.clear()
            self?.focus()
        }
        showClearButton()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        input.intrinsicContentSize
    }

    func focus() {
        input.focus()
    }

    private func cancel() {
        if let onCancel {
            onCancel()
        } else {
            clear()
        }
    }

    private func clear() {
        guard !stringValue.isEmpty else { return }
        stringValue = ""
        onChange?("")
    }

    private func showClearButton() {
        clearButton.isHidden = input.stringValue.isEmpty
    }
}
