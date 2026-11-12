import Testing
@testable import HoboshellCore

@Suite struct SwitcherKeyPolicyTests {
    private let tab = 48
    private let escape = 53
    private let keyQ = 12
    private let keyW = 13
    private let leftArrow = 123
    private let letterA = 0

    private func down(_ key: Int, command: Bool = false, option: Bool = false, control: Bool = false, shift: Bool = false) -> SwitcherKeyEvent {
        SwitcherKeyEvent(kind: .keyDown, keyCode: key, command: command, option: option, control: control, shift: shift)
    }

    private func decide(_ event: SwitcherKeyEvent, holder: SwitcherModifier? = nil, takes: Bool = true) -> SwitcherTapDecision {
        SwitcherKeyPolicy.decide(event, holder: holder, takesCommandTab: takes)
    }

    @Test func commandTabOpensTheSwitcherAndIsSwallowed() {
        #expect(decide(down(tab, command: true)) == SwitcherTapDecision(swallow: true, action: .open(forward: true)))
    }

    @Test func commandShiftTabOpensBackward() {
        #expect(decide(down(tab, command: true, shift: true)) == SwitcherTapDecision(swallow: true, action: .open(forward: false)))
    }

    @Test func commandTabPassesWhenTheSettingIsOff() {
        #expect(decide(down(tab, command: true), takes: false) == .pass)
    }

    @Test func plainTabPassesWhileHidden() {
        #expect(decide(down(tab)) == .pass)
    }

    @Test func optionTabPassesWhileHiddenForTheHotKey() {
        #expect(decide(down(tab, option: true)) == .pass)
    }

    @Test func commandOptionTabPassesWhileHidden() {
        #expect(decide(down(tab, command: true, option: true)) == .pass)
    }

    @Test func otherCommandShortcutsPassWhileHidden() {
        #expect(decide(down(keyQ, command: true)) == .pass)
    }

    @Test func tabAdvancesWhileShowing() {
        #expect(decide(down(tab, command: true), holder: .command) == SwitcherTapDecision(swallow: true, action: .advance(forward: true)))
    }

    @Test func shiftTabStepsBackWhileShowing() {
        #expect(decide(down(tab, command: true, shift: true), holder: .command) == SwitcherTapDecision(swallow: true, action: .advance(forward: false)))
    }

    @Test func arrowsMoveInTheGridWhileShowing() {
        #expect(decide(down(leftArrow, command: true), holder: .command) == SwitcherTapDecision(swallow: true, action: .move(.left)))
    }

    @Test func escapeCancelsWhileShowing() {
        #expect(decide(down(escape, command: true), holder: .command) == SwitcherTapDecision(swallow: true, action: .cancel))
    }

    @Test func qQuitsAndWClosesWhileShowing() {
        #expect(decide(down(keyQ, command: true), holder: .command).action == .quitSelected)
        #expect(decide(down(keyW, command: true), holder: .command).action == .closeSelected)
    }

    @Test func unrelatedKeysPassWhileShowing() {
        #expect(decide(down(letterA, command: true), holder: .command) == .pass)
    }

    @Test func releasingTheHeldModifierCommitsAndStillReachesApps() {
        let release = SwitcherKeyEvent(kind: .flagsChanged, keyCode: 55)
        #expect(decide(release, holder: .command) == SwitcherTapDecision(swallow: false, action: .commit))
    }

    @Test func otherModifierChangesPassWhileShowing() {
        let shiftDown = SwitcherKeyEvent(kind: .flagsChanged, keyCode: 56, command: true, shift: true)
        #expect(decide(shiftDown, holder: .command) == .pass)
    }

    @Test func optionHolderCommitsOnOptionRelease() {
        let release = SwitcherKeyEvent(kind: .flagsChanged, keyCode: 58, command: true)
        #expect(decide(release, holder: .option).action == .commit)
    }

    @Test func keyUpOfASwallowedKeyIsSwallowedWithoutAnAction() {
        let up = SwitcherKeyEvent(kind: .keyUp, keyCode: tab, command: true)
        #expect(decide(up, holder: .command) == SwitcherTapDecision(swallow: true, action: nil))
    }

    @Test func keyUpOfAnotherKeyPassesWhileShowing() {
        let up = SwitcherKeyEvent(kind: .keyUp, keyCode: letterA, command: true)
        #expect(decide(up, holder: .command) == .pass)
    }

    @Test func modifierChangesPassWhileHidden() {
        #expect(decide(SwitcherKeyEvent(kind: .flagsChanged, keyCode: 55, command: true)) == .pass)
    }
}
