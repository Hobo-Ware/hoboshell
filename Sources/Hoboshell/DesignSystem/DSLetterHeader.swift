import AppKit

final class DSLetterHeader: NSView {
    init(_ letter: String) {
        super.init(frame: .zero)
        let label = DSLabel(letter, style: .title, weight: .semibold, color: DSColor.accent)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityRole(.staticText)
        setAccessibilityLabel(letter)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: DSControlHeight.regular.value)
    }
}
