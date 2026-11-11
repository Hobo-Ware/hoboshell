import AppKit

final class DSSectionHeader: NSView {
    init(_ title: String) {
        super.init(frame: .zero)
        let label = DSLabel(title.uppercased(), style: .caption, weight: .semibold, color: DSColor.dimText)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: DSControlHeight.compact.value)
    }
}
