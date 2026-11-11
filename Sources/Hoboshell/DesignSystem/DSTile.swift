import AppKit
import HoboshellCore

final class DSTile: DSControl {
    static let width: CGFloat = 128
    static let size = NSSize(
        width: width,
        height: DSSpacing.s * 3 + DSIconSize.picture + nameStyle.lineHeight * CGFloat(maxLines)
    )

    private static let nameStyle = DSTextStyle.body
    private static let maxLines = 2
    private static let pictureCorner = DSRadius.control

    var onSelect: (() -> Void)?
    var onOpen: (() -> Void)?

    let label: NSTextField

    private let pictureView = NSImageView()
    private let pill = NSView()
    private let renameBox = DSFieldBox()
    private lazy var pictureWidth = pictureView.widthAnchor.constraint(equalToConstant: DSIconSize.picture)
    private lazy var pictureHeight = pictureView.heightAnchor.constraint(equalToConstant: DSIconSize.picture)
    private lazy var nameHeight = label.heightAnchor.constraint(equalToConstant: Self.nameStyle.lineHeight)
    private lazy var nameTop = label.topAnchor.constraint(equalTo: topAnchor)
    private lazy var nameLeading = label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s)
    private lazy var nameTrailing = label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s)
    private var fullName = ""
    private var widestLine: CGFloat = 0
    private var isRenaming = false

    override var isSelected: Bool {
        didSet { showName() }
    }

    init(label: NSTextField? = nil) {
        self.label = label ?? DSLabel()
        super.init(frame: NSRect(origin: .zero, size: Self.size))
        cornerRadius = DSRadius.card
        selectedFill = DSColor.accentTint

        pictureView.imageScaling = .scaleProportionallyUpOrDown
        pictureView.wantsLayer = true
        pictureView.layer?.cornerRadius = Self.pictureCorner
        pictureView.layer?.borderColor = DSColor.border.cgColor

        pill.wantsLayer = true
        pill.layer?.cornerRadius = DSRadius.control
        pill.layer?.backgroundColor = DSColor.accent.cgColor
        pill.isHidden = true

        renameBox.isHidden = true
        renameBox.isFocused = true

        self.label.font = Self.nameStyle.font()
        self.label.textColor = DSColor.text
        self.label.alignment = .center
        self.label.lineBreakMode = .byClipping
        self.label.maximumNumberOfLines = Self.maxLines
        self.label.translatesAutoresizingMaskIntoConstraints = false

        let slot = NSView()
        for view in [slot, renameBox, pictureView, self.label] {
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        addSubview(slot)
        slot.addSubview(pictureView)
        addSubview(renameBox)
        addSubview(pill)
        addSubview(self.label)
        NSLayoutConstraint.activate([
            slot.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.s),
            slot.centerXAnchor.constraint(equalTo: centerXAnchor),
            slot.widthAnchor.constraint(equalToConstant: DSIconSize.picture),
            slot.heightAnchor.constraint(equalToConstant: DSIconSize.picture),
            pictureView.centerXAnchor.constraint(equalTo: slot.centerXAnchor),
            pictureView.centerYAnchor.constraint(equalTo: slot.centerYAnchor),
            pictureWidth,
            pictureHeight,
            nameTop,
            nameLeading,
            nameTrailing,
            nameHeight,
            renameBox.topAnchor.constraint(equalTo: slot.bottomAnchor, constant: DSSpacing.s - DSSpacing.xs),
            renameBox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            renameBox.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
            renameBox.heightAnchor.constraint(equalToConstant: DSControlHeight.compact.value),
        ])
        showName()
        installRenameHooks()
    }

    func show(name: String, image: NSImage, isPicture: Bool) {
        fullName = name
        setAccessibilityLabel(name)
        showPicture(image, isPicture: isPicture)
        showName()
    }

    func showPicture(_ image: NSImage, isPicture: Bool) {
        let side = DSIconSize.picture
        let natural = image.size
        var fitted = NSSize(width: side, height: side)
        if isPicture, natural.width > 0, natural.height > 0 {
            let scale = min(side / natural.width, side / natural.height)
            fitted = NSSize(width: (natural.width * scale).rounded(), height: (natural.height * scale).rounded())
        }
        pictureWidth.constant = fitted.width
        pictureHeight.constant = fitted.height
        pictureView.image = image
        pictureView.layer?.borderWidth = isPicture ? 1 : 0
        pictureView.layer?.masksToBounds = isPicture
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let local = convert(point, from: superview)
        if label.isEditable, label.frame.contains(local) {
            return label
        }
        return super.hitTest(point)
    }

    override func layout() {
        super.layout()
        let height = label.frame.height + DSSpacing.xxs * 2
        let width = min(widestLine + DSSpacing.xs * 2, label.frame.width)
        pill.frame = NSRect(x: label.frame.midX - width / 2, y: label.frame.midY - height / 2, width: width, height: height)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard handlesClicks else { return }
        onSelect?()
        if event.clickCount == 2 {
            onOpen?()
        }
    }

    override func rightMouseDown(with event: NSEvent) {
        if handlesClicks {
            onSelect?()
        }
        super.rightMouseDown(with: event)
    }

    private func installRenameHooks() {
        guard let field = label as? ExplorerNameField else { return }
        field.onBeginRenaming = { [weak self] in
            self?.setRenaming(true)
        }
        field.onEndRenaming = { [weak self] in
            guard let self else { return }
            self.fullName = self.label.stringValue
            self.setRenaming(false)
        }
    }

    private func setRenaming(_ value: Bool) {
        isRenaming = value
        renameBox.isHidden = !value
        label.maximumNumberOfLines = value ? 1 : Self.maxLines
        label.cell?.usesSingleLineMode = value
        label.cell?.isScrollable = value
        let inset = value ? DSSpacing.s + DSSpacing.xs : DSSpacing.s
        nameLeading.constant = inset
        nameTrailing.constant = -inset
        showName()
        layoutSubtreeIfNeeded()
    }

    private func showName() {
        let font = Self.nameStyle.font()
        let lineHeight = Self.nameStyle.lineHeight
        guard !isRenaming else {
            label.stringValue = fullName
            label.textColor = DSColor.text
            pill.isHidden = true
            nameHeight.constant = lineHeight
            nameTop.constant = namesTop + (DSControlHeight.compact.value - lineHeight) / 2 - DSSpacing.xs
            needsLayout = true
            return
        }
        let textWidth = Self.width - (DSSpacing.s + DSSpacing.xs) * 2
        let lines = ExplorerNameLines.lines(for: fullName) { text in
            ceil((text as NSString).size(withAttributes: [.font: font]).width) <= textWidth
        }
        widestLine = lines.map { ceil(($0 as NSString).size(withAttributes: [.font: font]).width) }.max() ?? 0
        label.stringValue = lines.joined(separator: "\n")
        label.textColor = isSelected ? DSColor.onAccent : DSColor.text
        pill.isHidden = !isSelected
        nameHeight.constant = lineHeight * CGFloat(lines.count)
        nameTop.constant = namesTop
        needsLayout = true
    }

    private var namesTop: CGFloat {
        DSSpacing.s + DSIconSize.picture + DSSpacing.s
    }
}
