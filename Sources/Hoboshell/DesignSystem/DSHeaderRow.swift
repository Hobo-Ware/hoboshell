import AppKit

final class DSHeaderRow: NSView {
    init(title: String, leading: NSView? = nil, trailing: NSView? = nil) {
        super.init(frame: .zero)
        let label = DSSectionHeader.makeLabel(title)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let row = NSStackView(views: [leading, label, trailing].compactMap { $0 })
        row.orientation = .horizontal
        row.alignment = .centerY
        row.spacing = DSSpacing.xs
        if leading == nil {
            row.edgeInsets = NSEdgeInsets(top: 0, left: DSSpacing.s, bottom: 0, right: 0)
        }
        DSPanelStyle.pin(row, to: self)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: DSControlHeight.compact.value)
    }
}
