import AppKit

enum DSControlState: CaseIterable {
    case rest
    case hover
    case pressed
    case selected
    case disabled
    case focused

    var title: String {
        switch self {
        case .rest: return "rest"
        case .hover: return "hover"
        case .pressed: return "pressed"
        case .selected: return "selected"
        case .disabled: return "disabled"
        case .focused: return "focus"
        }
    }
}

class DSControl: NSView {
    private static let focusRingWidth: CGFloat = 2

    var onPress: (() -> Void)?
    var onHoverChange: ((Bool) -> Void)?
    var handlesClicks = true
    var tracksHover = true

    var restingFill: NSColor? {
        didSet { refresh() }
    }

    var cornerRadius = DSRadius.control {
        didSet { layer?.cornerRadius = cornerRadius }
    }

    var isSelected = false {
        didSet { refresh() }
    }

    var isEnabled = true {
        didSet {
            guard oldValue != isEnabled else { return }
            setHovered(false)
            isPressed = false
            refresh()
        }
    }

    private let hoverSync = DSHoverSync()

    private(set) var isHovered = false {
        didSet { refresh() }
    }

    private(set) var isPressed = false {
        didSet { refresh() }
    }

    private(set) var isFocused = false {
        didSet { refresh() }
    }

    private var isPreviewing = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = cornerRadius
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var acceptsFirstResponder: Bool {
        handlesClicks && isEnabled && !isPreviewing && NSApp.isFullKeyboardAccessEnabled
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func becomeFirstResponder() -> Bool {
        isFocused = true
        return true
    }

    override func resignFirstResponder() -> Bool {
        isFocused = false
        return true
    }

    override func keyDown(with event: NSEvent) {
        guard isEnabled, let keys = event.charactersIgnoringModifiers, keys == " " || keys == "\r" else {
            super.keyDown(with: event)
            return
        }
        activate()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hit = super.hitTest(point) else { return nil }
        return hit is DSControl ? hit : self
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        trackingAreas.forEach(removeTrackingArea)
        addTrackingArea(NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: self
        ))
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        hoverSync.follow(scrollingOf: self) { [weak self] in
            guard let self, self.tracksHover, self.isEnabled, !self.isPreviewing else { return }
            self.setHovered(DSHoverSync.isPointerInside(self))
        }
    }

    override func mouseEntered(with event: NSEvent) {
        guard tracksHover, isEnabled, !isPreviewing else { return }
        setHovered(true)
    }

    override func mouseExited(with event: NSEvent) {
        guard !isPreviewing else { return }
        setHovered(false)
    }

    override func mouseDown(with event: NSEvent) {
        guard handlesClicks, isEnabled, !isPreviewing else {
            super.mouseDown(with: event)
            return
        }
        isPressed = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard handlesClicks, isEnabled, isPressed else {
            super.mouseDragged(with: event)
            return
        }
        isPressed = contains(event)
    }

    override func mouseUp(with event: NSEvent) {
        guard handlesClicks, isEnabled, !isPreviewing else {
            super.mouseUp(with: event)
            return
        }
        let wasInside = contains(event)
        isPressed = false
        if wasInside {
            activate()
        }
    }

    override func accessibilityPerformPress() -> Bool {
        guard isEnabled else { return false }
        activate()
        return true
    }

    func activate() {
        onPress?()
    }

    func cancelPress() {
        isPressed = false
    }

    func preview(_ state: DSControlState) {
        isPreviewing = true
        isEnabled = state != .disabled
        isSelected = state == .selected
        isHovered = state == .hover
        isPressed = state == .pressed
        isFocused = state == .focused
    }

    private func contains(_ event: NSEvent) -> Bool {
        bounds.contains(convert(event.locationInWindow, from: nil))
    }

    private func setHovered(_ value: Bool) {
        guard isHovered != value else { return }
        isHovered = value
        onHoverChange?(value)
    }

    private var fill: NSColor? {
        if isPressed { return DSColor.pressed }
        if isSelected { return DSColor.selected }
        if isHovered { return DSColor.hover }
        return restingFill
    }

    private func refresh() {
        guard let layer else { return }
        alphaValue = isEnabled ? 1 : DSColor.disabledAlpha
        layer.borderWidth = isFocused ? Self.focusRingWidth : 0
        layer.borderColor = DSColor.focusRing.cgColor
        DSMotion.fill(layer, to: fill?.cgColor)
    }
}
