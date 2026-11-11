import AppKit

final class ExplorerCommandBar {
    let view: DSToolbar

    private let newFolderButton: DSButton
    private let cutButton: DSButton
    private let copyButton: DSButton
    private let pasteButton: DSButton
    private let renameButton: DSButton
    private let trashButton: DSButton
    private let hiddenButton: DSToggleButton
    private let viewSwitch: DSSegmentedSwitch

    init(target: ExplorerController) {
        newFolderButton = DSButton(
            title: "New folder",
            image: DSIconSize.symbol("folder.badge.plus"),
            tip: "New folder (Shift+Command+N)"
        )
        newFolderButton.onPress = { [weak target] in target?.newFolder() }
        cutButton = Self.button("scissors", tip: "Cut (Command+X)") { [weak target] in target?.cutSelection() }
        copyButton = Self.button("doc.on.doc", tip: "Copy (Command+C)") { [weak target] in target?.copySelection() }
        pasteButton = Self.button("doc.on.clipboard", tip: "Paste (Command+V)") { [weak target] in target?.paste() }
        renameButton = Self.button("character.cursor.ibeam", tip: "Rename (F2)") { [weak target] in target?.renameSelection() }
        trashButton = Self.button("trash", tip: "Move to Trash (Command+Delete)") { [weak target] in target?.trashSelection() }

        let sortButton = DSButton(title: "Sort", image: DSIconSize.symbol("arrow.up.arrow.down"), tip: "Sort")
        sortButton.onPress = { [weak target, weak sortButton] in
            guard let target, let sortButton else { return }
            target.showSortMenu(sortButton)
        }

        hiddenButton = DSToggleButton(symbol: "eye", tip: "Show hidden files")
        hiddenButton.onToggle = { [weak target] _ in target?.toggleHidden() }

        viewSwitch = DSSegmentedSwitch(segments: [
            DSSegmentedSwitch.Segment(symbol: "list.bullet", tip: "Details"),
            DSSegmentedSwitch.Segment(symbol: "square.grid.2x2", tip: "Icons"),
        ])
        viewSwitch.onChange = { [weak target] index in
            target?.setMode(index == 0 ? .details : .icons)
        }

        view = DSToolbar([
            .view(newFolderButton),
            .divider,
            .group([cutButton, copyButton, pasteButton, renameButton, trashButton]),
            .spacer,
            .view(sortButton),
            .view(viewSwitch),
            .view(hiddenButton),
        ])
    }

    func update(selectionCount: Int, canPaste: Bool, canWrite: Bool, showsHidden: Bool, mode: ExplorerViewMode) {
        let hasSelection = selectionCount > 0
        newFolderButton.isEnabled = canWrite
        cutButton.isEnabled = hasSelection
        copyButton.isEnabled = hasSelection
        pasteButton.isEnabled = canPaste && canWrite
        renameButton.isEnabled = hasSelection
        trashButton.isEnabled = hasSelection
        hiddenButton.isOn = showsHidden
        hiddenButton.image = DSIconSize.symbol(showsHidden ? "eye.slash" : "eye", description: "Show hidden files")
        viewSwitch.selectedIndex = mode == .details ? 0 : 1
    }

    private static func button(_ symbol: String, tip: String, action: @escaping () -> Void) -> DSButton {
        let button = DSButton(symbol: symbol, tip: tip)
        button.onPress = action
        return button
    }
}
