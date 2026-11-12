import AppKit
import HoboshellCore

final class ExplorerAddressBar: NSView {
    private static let separatorWidth = DSSpacing.m
    private static let collapsedTitle = "..."

    var onNavigate: ((URL) -> Void)?
    var onSubmit: ((String) -> Void)?
    var onFinish: (() -> Void)?

    private let box = DSFieldBox()
    private let folderIcon = DSIconView(side: DSIconSize.inline)
    private let editorIcon = DSIconView(side: DSIconSize.inline)
    private let editor: DSTextField
    private let crumbs = NSView()
    private let collapsed = ExplorerCrumb(title: collapsedTitle)
    private var segments: [BreadcrumbSegment] = []
    private var chips: [ExplorerCrumb] = []
    private var separators: [DSIconView] = []
    private var hiddenSegments = 0
    private(set) var isEditing = false

    override init(frame frameRect: NSRect) {
        editor = DSTextField(height: .regular, leading: editorIcon, radius: DSRadius.card)
        super.init(frame: frameRect)
        box.radius = DSRadius.card
        editor.field.lineBreakMode = .byTruncatingHead
        editor.isHidden = true
        editor.onSubmit = { [weak self] text in
            self?.endEditing()
            self?.onSubmit?(text)
            self?.onFinish?()
        }
        editor.onCancel = { [weak self] in
            self?.endEditing()
            self?.onFinish?()
        }
        editor.onEndEditing = { [weak self] in
            guard self?.isEditing == true else { return }
            self?.endEditing()
        }
        collapsed.onPress = { [weak self] in
            self?.showCollapsedMenu()
        }
        collapsed.isHidden = true
        crumbs.addSubview(collapsed)
        for view in [box, folderIcon, crumbs, editor] {
            addSubview(view)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: DSControlHeight.regular.value)
    }

    func show(_ folder: URL) {
        segments = Breadcrumbs.segments(for: folder, home: FileManager.default.homeDirectoryForCurrentUser)
        let icon = HoboIcon.image(forFile: folder.path)
        folderIcon.image = icon
        editorIcon.image = icon
        chips.forEach { $0.removeFromSuperview() }
        separators.forEach { $0.removeFromSuperview() }
        chips = segments.enumerated().map { index, segment in
            let chip = ExplorerCrumb(
                title: segment.name,
                symbol: segment.isHome ? "house" : nil,
                isCurrent: index == segments.count - 1
            )
            chip.onPress = { [weak self] in
                self?.navigate(to: index)
            }
            crumbs.addSubview(chip)
            return chip
        }
        separators = segments.dropFirst().map { _ in
            let separator = DSIconView(
                side: Self.separatorWidth,
                image: DSIconSize.symbol("chevron.right", weight: .semibold, pointSize: DSIconSize.chevron),
                tint: DSColor.dimText
            )
            crumbs.addSubview(separator)
            return separator
        }
        needsLayout = true
    }

    func beginEditing() {
        guard let url = segments.last?.url else { return }
        isEditing = true
        editor.stringValue = url.path
        editor.isHidden = false
        crumbs.isHidden = true
        folderIcon.isHidden = true
        editor.focus()
        editor.field.currentEditor()?.selectAll(nil)
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let hit = super.hitTest(point) else { return nil }
        return isEditing || hit is DSControl ? hit : self
    }

    override func mouseDown(with event: NSEvent) {
        beginEditing()
    }

    override func layout() {
        super.layout()
        box.frame = bounds
        editor.frame = bounds
        crumbs.frame = bounds
        let iconY = (bounds.height - DSIconSize.inline) / 2
        folderIcon.frame = NSRect(x: DSSpacing.s, y: iconY, width: DSIconSize.inline, height: DSIconSize.inline)
        layoutCrumbs()
    }

    private func navigate(to index: Int) {
        guard segments.indices.contains(index) else { return }
        onNavigate?(segments[index].url)
    }

    private func endEditing() {
        isEditing = false
        editor.isHidden = true
        crumbs.isHidden = false
        folderIcon.isHidden = false
    }

    private func showCollapsedMenu() {
        let items = segments.prefix(hiddenSegments).enumerated().map { index, segment in
            DSMenuItem(segment.name, symbol: segment.isHome ? "house" : nil) { [weak self] in
                self?.navigate(to: index)
            }
        }
        DSMenu.popUp(DSMenu.make(items), below: collapsed)
    }

    private func layoutCrumbs() {
        let start = folderIcon.frame.maxX + DSSpacing.xs
        let widths = chips.map { $0.intrinsicContentSize.width }
        let collapsedWidth = collapsed.intrinsicContentSize.width
        hiddenSegments = Breadcrumbs.hiddenCount(
            widths: widths,
            separatorWidth: Self.separatorWidth,
            collapsedWidth: collapsedWidth,
            available: bounds.width - start - DSSpacing.xs
        )
        let height = DSControlHeight.compact.value
        let y = (bounds.height - height) / 2
        let separatorY = (bounds.height - Self.separatorWidth) / 2
        var x = start
        collapsed.isHidden = hiddenSegments == 0
        if hiddenSegments > 0 {
            collapsed.frame = NSRect(x: x, y: y, width: collapsedWidth, height: height)
            x += collapsedWidth
        }
        for index in chips.indices {
            let isShown = index >= hiddenSegments
            chips[index].isHidden = !isShown
            if index > 0 {
                separators[index - 1].isHidden = !isShown
            }
        }
        for index in chips.indices where index >= hiddenSegments {
            if index > 0 {
                separators[index - 1].frame = NSRect(x: x, y: separatorY, width: Self.separatorWidth, height: Self.separatorWidth)
                x += Self.separatorWidth
            }
            chips[index].frame = NSRect(x: x, y: y, width: widths[index], height: height)
            x += widths[index]
        }
    }
}
