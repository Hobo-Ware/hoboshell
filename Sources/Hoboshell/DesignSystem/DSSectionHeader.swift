import AppKit

final class DSSectionHeader: NSView {
    static let height = DSSpacing.m + DSTextStyle.caption.lineHeight + DSSpacing.xs

    init(_ title: String) {
        super.init(frame: .zero)
        let label = DSLabel(title, style: .caption, weight: .medium, color: DSColor.dimText)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
            label.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.m),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: Self.height)
    }
}
