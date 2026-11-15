import AppKit
import HoboshellCore

final class DSNetworkRow: DSControl {
    private static let currentName = "Current network"

    var onDisconnect: (() -> Void)? {
        didSet { disconnectButton.onPress = onDisconnect }
    }

    private let signalIcon = DSIconView(side: DSIconSize.row)
    private let nameLabel = DSLabel("")
    private let statusLabel = DSLabel("", style: .caption, color: DSColor.dimText)
    private let lockIcon = DSIconView(side: DSIconSize.inline, image: DSIconSize.symbol("lock.fill"), tint: DSColor.dimText)
    private let disconnectButton = DSButton(title: "Disconnect", height: .row)
    private let content = NSStackView()
    private let topLine = NSStackView()
    private let actionLine = NSStackView()
    private var isCurrentRow = false
    private var plainConstraint: NSLayoutConstraint?
    private var currentConstraints: [NSLayoutConstraint] = []

    init(name: String = "", bars: Int = 0, isSecured: Bool = false, isCurrent: Bool = false) {
        super.init(frame: .zero)
        cornerRadius = DSRadius.card
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        statusLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        disconnectButton.restingFill = DSColor.faint
        disconnectButton.cornerRadius = DSRadius.control + DSSpacing.xxs

        topLine.setViews([signalIcon, nameLabel, lockIcon], in: .leading)
        topLine.orientation = .horizontal
        topLine.spacing = DSControlHeight.row.gap
        topLine.alignment = .centerY

        let spacer = NSView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        actionLine.setViews([spacer, disconnectButton], in: .leading)
        actionLine.orientation = .horizontal
        actionLine.alignment = .centerY

        let statusIndent = DSIconSize.row + DSControlHeight.row.gap
        let statusLine = NSStackView(views: [statusLabel])
        statusLine.edgeInsets = NSEdgeInsets(top: 0, left: statusIndent, bottom: 0, right: 0)

        content.setViews([topLine, statusLine, actionLine], in: .leading)
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = DSSpacing.xs
        content.translatesAutoresizingMaskIntoConstraints = false
        addSubview(content)
        plainConstraint = content.centerYAnchor.constraint(equalTo: centerYAnchor)
        currentConstraints = [
            content.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.s),
            content.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.s),
        ]
        plainConstraint?.isActive = true
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            content.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
            topLine.widthAnchor.constraint(equalTo: content.widthAnchor),
            statusLine.widthAnchor.constraint(equalTo: content.widthAnchor),
            actionLine.widthAnchor.constraint(equalTo: content.widthAnchor),
        ])
        setAccessibilityRole(.button)
        update(name: name, bars: bars, isSecured: isSecured, isCurrent: isCurrent)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        let height = isCurrentRow ? content.fittingSize.height + DSSpacing.s * 2 : DSControlHeight.row.value
        return NSSize(width: NSView.noIntrinsicMetric, height: height)
    }

    func makeStatic() {
        handlesClicks = false
        tracksHover = false
    }

    func update(name: String?, bars: Int, isSecured: Bool, isCurrent: Bool, status: String? = nil) {
        let shown = name ?? Self.currentName
        if nameLabel.stringValue != shown {
            nameLabel.stringValue = shown
        }
        signalIcon.image = DSIconSize.wifiSymbol(bars: bars)
        lockIcon.isHidden = !isSecured
        let statusText = isCurrent ? status ?? "Connected" : ""
        if statusLabel.stringValue != statusText {
            statusLabel.stringValue = statusText
        }
        content.arrangedSubviews[1].isHidden = !isCurrent
        actionLine.isHidden = !isCurrent
        restingFill = isCurrent ? DSColor.faint : nil
        if isCurrentRow != isCurrent {
            isCurrentRow = isCurrent
            plainConstraint?.isActive = !isCurrent
            currentConstraints.forEach { $0.isActive = isCurrent }
            invalidateIntrinsicContentSize()
        }
        let state = [isCurrent ? "connected" : nil, isSecured ? "secured" : nil, "signal \(bars) of \(WiFiSignal.maxBars)"].compactMap { $0 }
        setAccessibilityLabel("\(shown), \(state.joined(separator: ", "))")
    }
}
