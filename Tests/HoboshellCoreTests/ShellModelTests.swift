import Testing
@testable import HoboshellCore

@Suite struct ShellModelTests {
    private let twoApps = Shell.running(
        apps: [Shell.app(1, "mail"), Shell.app(2, "notes")],
        windows: [Shell.window(10, 1), Shell.window(11, 1), Shell.window(20, 2)]
    )

    @Test func neverGroupingGivesOneButtonPerWindow() {
        #expect(Shell.buttons(twoApps, grouping: .never).map(\.id) == ["w10", "w11", "w20"])
    }

    @Test func alwaysGroupingGivesOneButtonPerAppWithItsWindows() {
        let buttons = Shell.buttons(twoApps, grouping: .always)
        #expect(buttons.map(\.id) == ["a:mail", "w20"])
        #expect(buttons.map(\.windowIDs) == [[10, 11], [20]])
    }

    @Test func aGroupShowsTheAppNameAndASingleWindowShowsItsTitle() {
        let buttons = Shell.buttons(twoApps, grouping: .always)
        #expect(buttons.map(\.title) == ["App1", "Window20"])
    }

    @Test func aFullBarFoldsWindowsIntoGroups() {
        #expect(Shell.buttons(twoApps, grouping: .whenFull, width: 150).map(\.id) == ["a:mail", "w20"])
        #expect(Shell.buttons(twoApps, grouping: .whenFull, width: 1_200).map(\.id) == ["w10", "w11", "w20"])
    }

    @Test func pinnedAppsComeFirstEvenWhenNotRunning() {
        var state = twoApps
        state.apply(ShellEvent(.pinsChanged(TaskbarPins(["files", "notes"]))))
        let buttons = Shell.buttons(state)
        #expect(buttons.map(\.appID) == ["files", "notes", "mail", "mail"])
        #expect(buttons.map(\.isRunning) == [false, true, true, true])
        #expect(buttons[0].isIconOnly)
    }

    @Test func aRunningPinnedAppWithoutWindowsIsMarkedBackground() {
        var state = Shell.running(apps: [Shell.app(1, "mail")])
        state.apply(ShellEvent(.pinsChanged(TaskbarPins(["mail"]))))
        let button = Shell.buttons(state)[0]
        #expect(button.isBackground)
        #expect(button.isRunning)
    }

    @Test func aTitleChangeNeverReordersOrRenamesAnId() {
        var state = twoApps
        let before = Shell.buttons(state)
        state.apply(ShellEvent(.windowTitleChanged(id: 10, title: "Zzz")))
        let after = Shell.buttons(state)
        #expect(after.map(\.id) == before.map(\.id))
        #expect(after[0].title == "Zzz")
    }

    @Test func aNewWindowOfAnEarlierAppJoinsItsGroup() {
        var state = twoApps
        state.apply(ShellEvent(.windowCreated(Shell.window(12, 1))))
        #expect(Shell.buttons(state).map(\.id) == ["w10", "w11", "w12", "w20"])
    }

    @Test func aBadgeShowsOnARunningAppsButtons() {
        var state = twoApps
        state.apply(ShellEvent(.badgesRead(["mail": "5"])))
        #expect(Shell.buttons(state).map(\.badge) == ["5", "5", nil])
    }

    @Test func windowsOnAnotherDesktopHaveNoButton() {
        var state = twoApps
        state.apply(ShellEvent(.appSnapshot(pid: 2, windows: [], reason: .desktopChange)))
        #expect(Shell.buttons(state).map(\.id) == ["w10", "w11"])
    }

    @Test func theSwitcherListsMostRecentlyUsedFirst() {
        var state = Shell.running(apps: [Shell.app(1), Shell.app(2, active: true)], windows: [Shell.window(10, 1), Shell.window(11, 1), Shell.window(20, 2, focused: true)])
        state.apply(ShellEvent(.appActivated(pid: 2)))
        state.apply(ShellEvent(.appActivated(pid: 1)))
        state.apply(ShellEvent(.windowFocused(id: 11)))
        #expect(SwitcherModel.entries(state).map(\.windowID) == [11, 20, 10])
    }

    @Test func focusingAnInactiveAppsWindowDoesNotTouchTheOrder() {
        var state = twoApps
        state.apply(ShellEvent(.windowFocused(id: 20)))
        #expect(SwitcherModel.entries(state).map(\.windowID) == [10, 11, 20])
    }

    @Test func theSwitcherLeavesOutWindowsOnOtherDesktops() {
        var state = twoApps
        state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [], reason: .desktopChange)))
        #expect(SwitcherModel.entries(state).map(\.windowID) == [20])
    }

    @Test func theTrayListsWindowlessAppsInLaunchOrderWithBadges() {
        var state = Shell.running(apps: [Shell.app(1, "a"), Shell.app(2, "b"), Shell.app(3, "c")], windows: [Shell.window(20, 2)])
        state.apply(ShellEvent(.badgesRead(["c": "2"])))
        let entries = TrayModel.backgroundApps(state, excluded: [])
        #expect(entries.map(\.appID) == ["a", "c"])
        #expect(entries.map(\.badge) == [nil, "2"])
    }

    @Test func theTrayLeavesOutPinnedExcludedAndNonRegularApps() {
        var state = Shell.running(apps: [
            Shell.app(1, "pinned"), Shell.app(2, "finder"), Shell.app(3, "agent", policy: .accessory), Shell.app(4, "chat"),
        ])
        state.apply(ShellEvent(.pinsChanged(TaskbarPins(["pinned"]))))
        #expect(TrayModel.backgroundApps(state, excluded: ["finder"]).map(\.appID) == ["chat"])
    }

    @Test func accessoryAppsStillShowTheirWindows() {
        let state = Shell.running(apps: [Shell.app(1, "me", policy: .accessory)], windows: [Shell.window(10, 1)])
        #expect(Shell.buttons(state).map(\.id) == ["w10"])
    }

    @Test func listDiffFindsRemovedInsertedAndReordered() {
        let diff = ListDiff(old: ["a", "b", "c"], new: ["c", "a", "d"])
        #expect(diff.removed == ["b"])
        #expect(diff.inserted == ["d"])
        #expect(diff.isReordered)
    }

    @Test func listDiffOfTheSameOrderIsEmpty() {
        #expect(ListDiff(old: ["a", "b"], new: ["a", "b"]).isEmpty)
        #expect(!ListDiff(old: ["a", "b"], new: ["a", "b", "c"]).isEmpty)
        #expect(!ListDiff(old: ["a", "b"], new: ["a", "b", "c"]).isReordered)
    }
}
