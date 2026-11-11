import AppKit
import HoboshellCore

extension ExplorerController: ExplorerItemsDelegate {
    func itemsSelectionChanged() {
        guard !isReloading else { return }
        statusError = nil
        updateSelectionState()
    }

    func itemsOpen(at index: Int) {
        guard visibleEntries.indices.contains(index) else { return }
        let entry = visibleEntries[index]
        if entry.isFolder {
            navigate(to: entry.url)
        } else {
            openWithDefaultApp(entry.url)
        }
    }

    func itemsRenameBegan() {
        isRenaming = true
    }

    func itemsRename(at index: Int, to name: String) {
        isRenaming = false
        reloadWaitsForRename = false
        guard visibleEntries.indices.contains(index) else {
            reload()
            return
        }
        do {
            let renamed = try ExplorerFileOperations.rename(visibleEntries[index].url, to: name)
            reload(selecting: [renamed.path])
        } catch {
            reload()
            report(error)
        }
    }

    func itemsRenameCancelled() {
        isRenaming = false
        flushPendingReload()
    }

    func itemsSortChanged(_ sort: ExplorerSort) {
        applySort(sort)
    }

    func itemsHandle(_ event: NSEvent) -> Bool {
        let now = Date()
        let isTypingSpace = event.keyCode == Self.spaceKeyCode && typeAhead.isActive(at: now)
        let flags = event.modifierFlags
        let input = ExplorerKeyInput(
            characters: event.charactersIgnoringModifiers ?? "",
            keyCode: event.keyCode,
            command: flags.contains(.command),
            shift: flags.contains(.shift),
            option: flags.contains(.option),
            control: flags.contains(.control)
        )
        if !isTypingSpace, let action = ExplorerShortcut.action(for: input) {
            perform(action)
            return true
        }
        guard flags.intersection([.command, .control, .option]).isEmpty,
              let typed = event.characters, Self.isTypeable(typed) else { return false }
        selectMatch(for: typeAhead.append(typed, at: now))
        return true
    }

    func itemsMenu(overItem: Bool) -> NSMenu {
        overItem ? makeItemMenu() : makeEmptyMenu()
    }

    private static let spaceKeyCode: UInt16 = 49

    private static func isTypeable(_ text: String) -> Bool {
        !text.isEmpty && text.unicodeScalars.allSatisfy { scalar in
            !CharacterSet.controlCharacters.contains(scalar) && !(0xF700...0xF8FF).contains(scalar.value)
        }
    }

    private func selectMatch(for prefix: String) {
        let names = visibleEntries.map(\.name)
        guard let index = ExplorerTypeAhead.match(prefix: prefix, in: names, selected: items.selectedIndexes.first) else { return }
        items.selectedIndexes = IndexSet(integer: index)
        items.reveal(index)
        updateSelectionState()
    }
}
