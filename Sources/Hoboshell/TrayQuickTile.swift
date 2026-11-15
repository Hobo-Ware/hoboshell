import AppKit

final class TrayQuickTile: NSView {
    private static let labelLines = 2
    private static let labelGap = DSSpacing.xs + 1

    var onPress: (() -> Void)? {
        get { tile.onPress }
        set { tile.onPress = newValue }
    }

    var onArrow: (() -> Void)? {
        get { tile.onArrow }
        set { tile.onArrow = newValue }
    }

    var isOn: Bool {
        get { tile.isOn }
        set {
            tile.isOn = newValue
            applyLabelColor()
        }
    }

    var isEnabled: Bool {
        get { tile.isEnabled }
        set {
            tile.isEnabled = newValue
            label.alphaValue = newValue ? 1 : DSColor.disabledAlpha
        }
    }

    private let tile: DSToggleTile
    private let label = DSLabel("", style: .caption)

    init(symbol: String, title: String, accessory: DSToggleTile.Accessory = .none) {
        tile = DSToggleTile(symbol: symbol, title: title, accessory: accessory)
        super.init(frame: .zero)
        label.alignment = .center
        label.lineBreakMode = .byTruncatingMiddle
        label.maximumNumberOfLines = Self.labelLines
        label.usesSingleLineMode = false
        label.cell?.truncatesLastVisibleLine = true
        label.translatesAutoresizingMaskIntoConstraints = false
        tile.translatesAutoresizingMaskIntoConstraints = false
        addSubview(tile)
        addSubview(label)
        let labelHeight = DSTextStyle.caption.lineHeight * CGFloat(Self.labelLines)
        NSLayoutConstraint.activate([
            tile.leadingAnchor.constraint(equalTo: leadingAnchor),
            tile.trailingAnchor.constraint(equalTo: trailingAnchor),
            tile.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.xxs),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.xxs),
            label.topAnchor.constraint(equalTo: tile.bottomAnchor, constant: Self.labelGap),
            label.heightAnchor.constraint(equalToConstant: labelHeight),
            label.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        applyLabelColor()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func mouseDown(with event: NSEvent) {}

    override func mouseUp(with event: NSEvent) {
        guard tile.isEnabled, bounds.contains(convert(event.locationInWindow, from: nil)) else { return }
        tile.activate()
    }

    func update(symbol: String, title: String, label text: String, detail: String) {
        tile.update(symbol: symbol, title: title, detail: detail)
        if label.stringValue != text {
            label.stringValue = text
        }
    }

    private func applyLabelColor() {
        label.textColor = tile.isOn ? DSColor.text : DSColor.dimText
    }
}
