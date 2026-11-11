import AppKit

final class GalleryWindow: NSWindow {
    private static let initialSize = NSSize(width: 1120, height: 860)

    init() {
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.initialSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        title = "Hoboshell design system"
        isReleasedWhenClosed = false
        appearance = NSAppearance(named: .darkAqua)
        backgroundColor = DSColor.surface

        let page = GalleryContent.page()
        page.translatesAutoresizingMaskIntoConstraints = false
        let document = GalleryDocumentView()
        document.addSubview(page)
        let scroll = NSScrollView()
        scroll.documentView = document
        scroll.hasVerticalScroller = true
        scroll.drawsBackground = false
        contentView = scroll
        NSLayoutConstraint.activate([
            document.widthAnchor.constraint(equalTo: scroll.contentView.widthAnchor),
            page.leadingAnchor.constraint(equalTo: document.leadingAnchor, constant: DSSpacing.xl),
            page.trailingAnchor.constraint(lessThanOrEqualTo: document.trailingAnchor, constant: -DSSpacing.xl),
            page.topAnchor.constraint(equalTo: document.topAnchor, constant: DSSpacing.xl),
            page.bottomAnchor.constraint(equalTo: document.bottomAnchor, constant: -DSSpacing.xl),
        ])
    }

    override var canBecomeKey: Bool { true }
}

private final class GalleryDocumentView: NSView {
    override var isFlipped: Bool { true }

    init() {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
