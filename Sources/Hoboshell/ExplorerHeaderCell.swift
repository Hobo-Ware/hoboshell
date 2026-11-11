import AppKit

final class ExplorerHeaderCell: NSTableHeaderCell {
    private static let arrowHeight: CGFloat = 8
    private static let style = DSTextStyle.caption

    private let sortKey: String
    private let leadingInset: CGFloat
    private let trailingInset: CGFloat
    private let titleAlignment: NSTextAlignment

    init(title: String, sortKey: String, leadingInset: CGFloat, trailingInset: CGFloat, alignment: NSTextAlignment) {
        self.sortKey = sortKey
        self.leadingInset = leadingInset
        self.trailingInset = trailingInset
        titleAlignment = alignment
        super.init(textCell: title)
    }

    @available(*, unavailable)
    required init(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        drawInterior(withFrame: cellFrame, in: controlView)
    }

    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: Self.style.font(.medium),
            .foregroundColor: DSColor.dimText,
        ]
        let title = stringValue as NSString
        let natural = title.size(withAttributes: attributes)
        let arrow = sortArrow(in: controlView)
        let arrowRoom = arrow.map { _ in Self.arrowHeight + DSSpacing.xs } ?? 0
        let textWidth = min(ceil(natural.width), cellFrame.width - leadingInset - trailingInset - arrowRoom)
        let textY = cellFrame.midY - natural.height / 2
        let rightAligned = titleAlignment == .right
        let textX = rightAligned ? cellFrame.maxX - trailingInset - textWidth : cellFrame.minX + leadingInset
        title.draw(in: NSRect(x: textX, y: textY, width: textWidth, height: natural.height), withAttributes: attributes)
        guard let arrow else { return }
        let scale = Self.arrowHeight / arrow.size.height
        let size = NSSize(width: arrow.size.width * scale, height: Self.arrowHeight)
        let arrowX = rightAligned ? textX - DSSpacing.xs - size.width : textX + textWidth + DSSpacing.xs
        arrow.draw(
            in: NSRect(x: arrowX, y: cellFrame.midY - size.height / 2, width: size.width, height: size.height),
            from: .zero,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: nil
        )
    }

    private func sortArrow(in controlView: NSView) -> NSImage? {
        guard let descriptor = (controlView as? NSTableHeaderView)?.tableView?.sortDescriptors.first,
              descriptor.key == sortKey else { return nil }
        let config = NSImage.SymbolConfiguration(pointSize: Self.arrowHeight, weight: .semibold)
            .applying(NSImage.SymbolConfiguration(paletteColors: [DSColor.dimText]))
        return DSIconSize.symbol(descriptor.ascending ? "chevron.up" : "chevron.down")?.withSymbolConfiguration(config)
    }
}
