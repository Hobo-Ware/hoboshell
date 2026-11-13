import Testing
@testable import HoboshellCore

@Suite struct ExplorerShortcutTests {
    private func command(_ characters: String, keyCode: UInt16 = 0, shift: Bool = false) -> ExplorerAction? {
        ExplorerShortcut.action(for: ExplorerKeyInput(characters: characters, keyCode: keyCode, command: true, shift: shift))
    }

    private func plain(_ keyCode: UInt16, characters: String = "") -> ExplorerAction? {
        ExplorerShortcut.action(for: ExplorerKeyInput(characters: characters, keyCode: keyCode))
    }

    @Test func commandBracketsNavigateHistory() {
        #expect(command("[") == .back)
        #expect(command("]") == .forward)
    }

    @Test func commandLettersMapToClipboardAndSelection() {
        #expect(command("c") == .copy)
        #expect(command("x") == .cut)
        #expect(command("v") == .paste)
        #expect(command("a") == .selectAll)
    }

    @Test func commandShiftNMakesAFolder() {
        #expect(command("n", shift: true) == .newFolder)
        #expect(command("n") == nil)
    }

    @Test func commandLFocusesTheAddressAndFTheSearch() {
        #expect(command("l") == .focusAddress)
        #expect(command("f") == .focusSearch)
    }

    @Test func commandUpGoesUpAndCommandDeleteTrashes() {
        #expect(command("", keyCode: 126) == .up)
        #expect(command("", keyCode: 51) == .trash)
    }

    @Test func commandDownOpens() {
        #expect(command("", keyCode: 125) == .open)
    }

    @Test func enterOpensAndBackspaceGoesUp() {
        #expect(plain(36) == .open)
        #expect(plain(76) == .open)
        #expect(plain(51) == .up)
    }

    @Test func f2RenamesAndF5Refreshes() {
        #expect(plain(120) == .rename)
        #expect(plain(96) == .refresh)
    }

    @Test func spaceOpensQuickLook() {
        #expect(plain(49, characters: " ") == .quickLook)
    }

    @Test func plainLettersAreNotShortcuts() {
        #expect(plain(8, characters: "c") == nil)
    }

    @Test func controlAndOptionCombinationsAreIgnored() {
        #expect(ExplorerShortcut.action(for: ExplorerKeyInput(characters: "c", keyCode: 8, command: true, control: true)) == nil)
        #expect(ExplorerShortcut.action(for: ExplorerKeyInput(characters: "c", keyCode: 8, command: true, option: true)) == nil)
        #expect(ExplorerShortcut.action(for: ExplorerKeyInput(characters: "", keyCode: 36, option: true)) == nil)
    }

    @Test func shiftedCommandLettersAreNotClipboardShortcuts() {
        #expect(command("c", shift: true) == nil)
    }
}
