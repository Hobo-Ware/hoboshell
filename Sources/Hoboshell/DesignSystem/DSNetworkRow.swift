import AppKit
import HoboshellCore

final class DSNetworkRow: DSControl {
    private let signalIcon = DSIconView(side: DSIconSize.row)
    private let nameLabel = DSLabel("")
    private let lockIcon = DSIconView(side: DSIconSize.inline, image: DSIconSize.symbol("lock.fill"), tint: DSColor.dimText)
    private let tickIcon = DSIconView(side: DSIconSize.inline, image: DSIconSize.symbol("checkmark"))

    init(name: String = "", bars: Int = 0, isSecured: Bool = false, isCurrent: Bool = false) {
        super.init(frame: .zero)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let row = NSStackView(views: [signalIcon, nameLabel, lockIcon, tickIcon])
        row.orientation = .horizontal
        row.spacing = DSControlHeight.row.gap
        row.alignment = .centerY
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            row.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
            row.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        setAccessibilityRole(.button)
        update(name: name, bars: bars, isSecured: isSecured, isCurrent: isCurrent)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: DSControlHeight.row.value)
    }

    func makeStatic() {
        handlesClicks = false
        tracksHover = false
    }

    func update(name: String, bars: Int, isSecured: Bool, isCurrent: Bool) {
        if nameLabel.stringValue != name {
            nameLabel.stringValue = name
        }
        signalIcon.image = DSIconSize.wifiSymbol(bars: bars)
        lockIcon.isHidden = !isSecured
        tickIcon.isHidden = !isCurrent
        let state = [isCurrent ? "connected" : nil, isSecured ? "secured" : nil, "signal \(bars) of \(WiFiSignal.maxBars)"].compactMap { $0 }
        setAccessibilityLabel("\(name), \(state.joined(separator: ", "))")
    }
}
