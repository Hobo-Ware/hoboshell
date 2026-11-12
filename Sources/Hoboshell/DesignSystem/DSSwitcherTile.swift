import AppKit

final class DSSwitcherTile: DSControl {
    static let pictureSize = CGSize(width: 200, height: 125)
    static let size = NSSize(
        width: pictureSize.width + DSSpacing.s * 2,
        height: DSSpacing.s + pictureSize.height + DSSpacing.xs + DSTextStyle.body.lineHeight + DSSpacing.s
    )

    private let frameView = NSView()
    private let placeholder = DSIconView(side: DSIconSize.grid)
    private let pictureView = NSImageView()
    private let badge = DSIconView(side: DSIconSize.taskbar)
    private let titleLabel = DSLabel(style: .body)

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        cornerRadius = DSRadius.card
        selectedFill = DSColor.accentTint
        tracksHover = false

        frameView.wantsLayer = true
        frameView.layer?.cornerRadius = DSRadius.control
        frameView.layer?.masksToBounds = true
        frameView.layer?.backgroundColor = DSColor.field.cgColor
        frameView.layer?.borderWidth = 1
        frameView.layer?.borderColor = DSColor.border.cgColor
        pictureView.imageScaling = .scaleProportionallyUpOrDown
        pictureView.isHidden = true
        titleLabel.alignment = .center

        for view in [frameView, titleLabel, placeholder, pictureView, badge] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(frameView)
        addSubview(titleLabel)
        frameView.addSubview(placeholder)
        frameView.addSubview(pictureView)
        frameView.addSubview(badge)
        NSLayoutConstraint.activate([
            frameView.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.s),
            frameView.centerXAnchor.constraint(equalTo: centerXAnchor),
            frameView.widthAnchor.constraint(equalToConstant: Self.pictureSize.width),
            frameView.heightAnchor.constraint(equalToConstant: Self.pictureSize.height),
            placeholder.centerXAnchor.constraint(equalTo: frameView.centerXAnchor),
            placeholder.centerYAnchor.constraint(equalTo: frameView.centerYAnchor),
            pictureView.leadingAnchor.constraint(equalTo: frameView.leadingAnchor),
            pictureView.trailingAnchor.constraint(equalTo: frameView.trailingAnchor),
            pictureView.topAnchor.constraint(equalTo: frameView.topAnchor),
            pictureView.bottomAnchor.constraint(equalTo: frameView.bottomAnchor),
            badge.trailingAnchor.constraint(equalTo: frameView.trailingAnchor, constant: -DSSpacing.xs),
            badge.bottomAnchor.constraint(equalTo: frameView.bottomAnchor, constant: -DSSpacing.xs),
            titleLabel.topAnchor.constraint(equalTo: frameView.bottomAnchor, constant: DSSpacing.xs),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
        ])
    }

    convenience init() {
        self.init(frame: NSRect(origin: .zero, size: Self.size))
    }

    override var intrinsicContentSize: NSSize {
        Self.size
    }

    func show(title: String, icon: NSImage?) {
        titleLabel.stringValue = title
        placeholder.image = icon
        badge.image = icon
        setAccessibilityLabel(title)
    }

    func show(picture: NSImage) {
        pictureView.image = picture
        pictureView.isHidden = false
        placeholder.isHidden = true
    }
}
