import AppKit

final class PreviewCardStrip: NSScrollView {
    private static let wheelLineStep: CGFloat = 12

    private let stack = NSStackView()

    init(cards: [PreviewCardView]) {
        super.init(frame: .zero)
        stack.orientation = .horizontal
        stack.spacing = DSSpacing.s
        stack.edgeInsets = NSEdgeInsets(top: DSSpacing.s, left: DSSpacing.s, bottom: DSSpacing.s, right: DSSpacing.s)
        cards.forEach(stack.addArrangedSubview)
        stack.translatesAutoresizingMaskIntoConstraints = false
        documentView = stack
        drawsBackground = false
        hasHorizontalScroller = true
        hasVerticalScroller = false
        autohidesScrollers = true
        scrollerStyle = .overlay
        horizontalScrollElasticity = .allowed
        verticalScrollElasticity = .none
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    var desiredSize: NSSize {
        stack.fittingSize
    }

    override func scrollWheel(with event: NSEvent) {
        guard abs(event.scrollingDeltaY) > abs(event.scrollingDeltaX), let document = documentView else {
            super.scrollWheel(with: event)
            return
        }
        let step = event.hasPreciseScrollingDeltas ? event.scrollingDeltaY : event.scrollingDeltaY * Self.wheelLineStep
        let furthest = max(document.frame.width - contentView.bounds.width, 0)
        let x = min(max(contentView.bounds.origin.x - step, 0), furthest)
        contentView.scroll(to: NSPoint(x: x, y: contentView.bounds.origin.y))
        reflectScrolledClipView(contentView)
    }
}
