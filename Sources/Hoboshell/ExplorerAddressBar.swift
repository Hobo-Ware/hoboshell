import AppKit
import HoboshellCore

final class ExplorerAddressBar: NSView {
    private static let inset = DSSpacing.xs
    private static let separatorWidth = DSSpacing.m

    var onNavigate: ((URL) -> Void)?
    var onSubmit: ((String) -> Void)?
    var onFinish: (() -> Void)?

    private let box = DSFieldBox()
    private let editor = DSTextField()
    private let crumbs = NSView()
    private var segments: [BreadcrumbSegment] = []
    private var crumbButtons: [DSButton] = []
    private var separators: [DSLabel] = []
    private let ellipsis = DSButton(title: "...", height: .compact)
    private var ellipsisTarget = 0
    private(set) var isEditing = false

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
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
        ellipsis.onPress = { [weak self] in
            guard let self else { return }
            self.navigate(to: self.ellipsisTarget)
        }
        ellipsis.isHidden = true
        crumbs.addSubview(ellipsis)
        addSubview(box)
        addSubview(crumbs)
        addSubview(editor)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: DSControlHeight.regular.value)
    }

    func show(_ folder: URL) {
        segments = Breadcrumbs.segments(for: folder)
        crumbButtons.forEach { $0.removeFromSuperview() }
        separators.forEach { $0.removeFromSuperview() }
        crumbButtons = segments.enumerated().map { index, segment in
            let button = DSButton(title: segment.name, height: .compact)
            button.onPress = { [weak self] in
                self?.navigate(to: index)
            }
            crumbs.addSubview(button)
            return button
        }
        separators = segments.dropFirst().map { _ in
            let label = DSLabel(">", style: .caption, color: DSColor.dimText)
            label.alignment = .center
            crumbs.addSubview(label)
            return label
        }
        needsLayout = true
    }

    func beginEditing() {
        guard let url = segments.last?.url else { return }
        isEditing = true
        editor.stringValue = url.path
        editor.isHidden = false
        crumbs.isHidden = true
        editor.focus()
        editor.field.currentEditor()?.selectAll(nil)
    }

    override func mouseDown(with event: NSEvent) {
        beginEditing()
    }

    override func layout() {
        super.layout()
        box.frame = bounds
        editor.frame = bounds
        crumbs.frame = bounds
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
    }

    private func layoutCrumbs() {
        let widths = crumbButtons.map { $0.intrinsicContentSize.width }
        let ellipsisWidth = ellipsis.intrinsicContentSize.width
        let available = bounds.width - 2 * Self.inset
        var used: CGFloat = 0
        var firstShown = crumbButtons.count
        for index in crumbButtons.indices.reversed() {
            let needed = widths[index] + (index > 0 ? Self.separatorWidth : 0)
            let reserve = index > 0 ? ellipsisWidth : 0
            if used + needed + reserve > available && firstShown < crumbButtons.count { break }
            used += needed
            firstShown = index
        }
        let crumbHeight = DSControlHeight.compact.value
        let y = (bounds.height - crumbHeight) / 2
        var x = Self.inset
        ellipsis.isHidden = firstShown == 0
        if firstShown > 0 {
            ellipsisTarget = firstShown - 1
            ellipsis.frame = NSRect(x: x, y: y, width: ellipsisWidth, height: crumbHeight)
            x += ellipsisWidth
        }
        for index in crumbButtons.indices {
            let visible = index >= firstShown
            crumbButtons[index].isHidden = !visible
            if index > 0 { separators[index - 1].isHidden = !visible }
            guard visible else { continue }
            if index > 0 {
                let separator = separators[index - 1]
                let separatorHeight = separator.intrinsicContentSize.height
                separator.frame = NSRect(
                    x: x,
                    y: (bounds.height - separatorHeight) / 2,
                    width: Self.separatorWidth,
                    height: separatorHeight
                )
                x += Self.separatorWidth
            }
            crumbButtons[index].frame = NSRect(x: x, y: y, width: widths[index], height: crumbHeight)
            x += widths[index]
        }
    }
}
