import AppKit

final class DSLabel: NSTextField {
    init(
        _ text: String = "",
        style: DSTextStyle = .body,
        weight: DSTextWeight = .regular,
        color: NSColor = DSColor.text,
        monospacedDigits: Bool = false
    ) {
        super.init(frame: .zero)
        isEditable = false
        isSelectable = false
        isBordered = false
        drawsBackground = false
        lineBreakMode = .byTruncatingTail
        stringValue = text
        font = style.font(weight, monospacedDigits: monospacedDigits)
        textColor = color
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
