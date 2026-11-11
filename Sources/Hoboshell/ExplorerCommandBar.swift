import AppKit

final class ExplorerCommandBar: NSView {
    private static let horizontalInset: CGFloat = 8
    private static let spacing: CGFloat = 2
    private static let newFolderWidth: CGFloat = 104
    private static let sortWidth: CGFloat = 76
    private static let segmentedWidth: CGFloat = 76

    private let newFolderButton: HoverButton
    private let cutButton: HoverButton
    private let copyButton: HoverButton
    private let pasteButton: HoverButton
    private let renameButton: HoverButton
    private let trashButton: HoverButton
    private let sortButton: HoverButton
    private let hiddenButton: HoverButton
    private let viewSwitch: NSSegmentedControl

    init(target: ExplorerController) {
        newFolderButton = ExplorerTheme.button(
            symbol: "folder.badge.plus", title: " New folder", tip: "New folder (Shift+Command+N)",
            width: Self.newFolderWidth, target: target, action: #selector(ExplorerController.newFolder)
        )
        cutButton = ExplorerTheme.button(symbol: "scissors", tip: "Cut (Command+X)", target: target, action: #selector(ExplorerController.cutSelection))
        copyButton = ExplorerTheme.button(symbol: "doc.on.doc", tip: "Copy (Command+C)", target: target, action: #selector(ExplorerController.copySelection))
        pasteButton = ExplorerTheme.button(symbol: "doc.on.clipboard", tip: "Paste (Command+V)", target: target, action: #selector(ExplorerController.paste))
        renameButton = ExplorerTheme.button(symbol: "character.cursor.ibeam", tip: "Rename (F2)", target: target, action: #selector(ExplorerController.renameSelection))
        trashButton = ExplorerTheme.button(symbol: "trash", tip: "Move to Trash (Command+Delete)", target: target, action: #selector(ExplorerController.trashSelection))
        sortButton = ExplorerTheme.button(
            symbol: "arrow.up.arrow.down", title: " Sort", tip: "Sort",
            width: Self.sortWidth, target: target, action: #selector(ExplorerController.showSortMenu(_:))
        )
        hiddenButton = ExplorerTheme.button(symbol: "eye", tip: "Show hidden files", target: target, action: #selector(ExplorerController.toggleHidden))
        viewSwitch = NSSegmentedControl(
            images: [
                ExplorerTheme.symbol("list.bullet") ?? NSImage(),
                ExplorerTheme.symbol("square.grid.2x2") ?? NSImage(),
            ],
            trackingMode: .selectOne,
            target: target,
            action: #selector(ExplorerController.viewModeChanged(_:))
        )
        super.init(frame: .zero)

        viewSwitch.selectedSegment = 0
        viewSwitch.setToolTip("Details", forSegment: 0)
        viewSwitch.setToolTip("Icons", forSegment: 1)
        viewSwitch.translatesAutoresizingMaskIntoConstraints = false
        viewSwitch.widthAnchor.constraint(equalToConstant: Self.segmentedWidth).isActive = true

        let spacer = NSView()
        spacer.setContentHuggingPriority(NSLayoutConstraint.Priority(1), for: .horizontal)
        let left: [NSView] = [newFolderButton, cutButton, copyButton, pasteButton, renameButton, trashButton]
        let right: [NSView] = [sortButton, viewSwitch, hiddenButton]
        let row = NSStackView(views: left + [spacer] + right)
        row.orientation = .horizontal
        row.spacing = Self.spacing
        row.alignment = .centerY
        row.distribution = .fill
        row.edgeInsets = NSEdgeInsets(top: 0, left: Self.horizontalInset, bottom: 0, right: Self.horizontalInset)
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    func update(selectionCount: Int, canPaste: Bool, canWrite: Bool, showsHidden: Bool, mode: ExplorerViewMode) {
        let hasSelection = selectionCount > 0
        ExplorerTheme.setEnabled(newFolderButton, canWrite)
        ExplorerTheme.setEnabled(cutButton, hasSelection)
        ExplorerTheme.setEnabled(copyButton, hasSelection)
        ExplorerTheme.setEnabled(pasteButton, canPaste && canWrite)
        ExplorerTheme.setEnabled(renameButton, hasSelection)
        ExplorerTheme.setEnabled(trashButton, hasSelection)
        hiddenButton.restingBackground = showsHidden ? ShellButton.activeBackground : nil
        hiddenButton.image = ExplorerTheme.symbol(showsHidden ? "eye.slash" : "eye")
        viewSwitch.selectedSegment = mode == .details ? 0 : 1
    }
}
