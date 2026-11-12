import Testing
@testable import HoboshellCore

@Suite struct ShellReducerTests {
    @Test func aLaunchedAppIsAddedAndReportedOnce() {
        var state = ShellState()
        let change = state.apply(ShellEvent(.appLaunched(Shell.app(1))))
        #expect(change.appsAdded == [1])
        #expect(state.apps.map(\.pid) == [1])
    }

    @Test func launchingTheSameAppTwiceChangesNothing() {
        var state = Shell.state(.appLaunched(Shell.app(1)))
        let before = state
        let change = state.apply(ShellEvent(.appLaunched(Shell.app(1))))
        #expect(change.isEmpty)
        #expect(state == before)
    }

    @Test func anAppIsNotBackgroundUntilItsWindowsHaveBeenRead() {
        var state = Shell.state(.appLaunched(Shell.app(1)))
        #expect(TrayModel.backgroundApps(state, excluded: []).isEmpty)
        state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [], reason: .launch)))
        #expect(TrayModel.backgroundApps(state, excluded: []).map(\.pid) == [1])
    }

    @Test func theFirstWindowAddsAButtonAndTakesTheAppOutOfTheTray() {
        var state = Shell.running(apps: [Shell.app(1)])
        let change = state.apply(ShellEvent(.windowCreated(Shell.window(10, 1))))
        #expect(change.windowsAdded == [10])
        #expect(Shell.buttons(state).map(\.id) == ["w10"])
        #expect(TrayModel.backgroundApps(state, excluded: []).isEmpty)
    }

    @Test func aSecondWindowAddsASecondButton() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        state.apply(ShellEvent(.windowCreated(Shell.window(11, 1))))
        #expect(Shell.buttons(state).map(\.id) == ["w10", "w11"])
    }

    @Test func aTitleChangeUpdatesTheWindowAndNothingElse() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1, "Old")])
        let change = state.apply(ShellEvent(.windowTitleChanged(id: 10, title: "New")))
        var expected = ShellChange()
        expected.windowsChanged = [10]
        #expect(change == expected)
        #expect(state.window(id: 10)?.title == "New")
    }

    @Test func theSameTitleAgainChangesNothing() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1, "Same")])
        #expect(state.apply(ShellEvent(.windowTitleChanged(id: 10, title: "Same"))).isEmpty)
    }

    @Test func minimisingAndRestoringKeepTheButton() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        state.apply(ShellEvent(.windowMinimized(id: 10)))
        #expect(Shell.buttons(state).map(\.id) == ["w10"])
        #expect(state.window(id: 10)?.isMinimized == true)
        state.apply(ShellEvent(.windowRestored(id: 10)))
        #expect(Shell.buttons(state).map(\.id) == ["w10"])
        #expect(state.window(id: 10)?.isMinimized == false)
    }

    @Test func aDestroyedWindowLeavesAtOnce() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1), Shell.window(11, 1)])
        let change = state.apply(ShellEvent(.windowDestroyed(id: 10)))
        #expect(change.windowsRemoved == [10])
        #expect(Shell.buttons(state).map(\.id) == ["w11"])
    }

    @Test func theLastWindowDestroyedMakesTheAppBackgroundAtOnce() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        state.apply(ShellEvent(.windowDestroyed(id: 10)))
        #expect(TrayModel.backgroundApps(state, excluded: []).map(\.pid) == [1])
    }

    @Test func aTerminatedAppTakesItsWindowsAndHistoryWithIt() {
        var state = Shell.running(apps: [Shell.app(1, active: true), Shell.app(2)], windows: [Shell.window(10, 1, focused: true), Shell.window(20, 2)])
        state.apply(ShellEvent(.appActivated(pid: 1)))
        let change = state.apply(ShellEvent(.appTerminated(pid: 1)))
        #expect(change.appsRemoved == [1])
        #expect(change.windowsRemoved == [10])
        #expect(state.windows.map(\.id) == [20])
        #expect(SwitcherModel.entries(state).map(\.windowID) == [20])
    }

    @Test func aDesktopChangeSnapshotKeepsTheAppOutOfTheBackgroundList() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        state.apply(ShellEvent(.desktopChanged))
        state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [], reason: .desktopChange)))
        #expect(Shell.buttons(state).isEmpty)
        #expect(TrayModel.backgroundApps(state, excluded: []).isEmpty)
        #expect(state.window(id: 10)?.isOnThisDesktop == false)
    }

    @Test func comingBackToTheDesktopBringsTheSameWindowBack() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [], reason: .desktopChange)))
        state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [Shell.window(10, 1)], reason: .desktopChange)))
        #expect(Shell.buttons(state).map(\.id) == ["w10"])
    }

    @Test func aDesktopChangeIsNotDrift() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        let change = state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [], reason: .desktopChange)))
        #expect(change.drift.isEmpty)
    }

    @Test func aWindowDestroyedWhileOnAnotherDesktopLeavesTheModel() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [], reason: .desktopChange)))
        state.apply(ShellEvent(.windowDestroyed(id: 10)))
        #expect(TrayModel.backgroundApps(state, excluded: []).map(\.pid) == [1])
    }

    @Test func windowEventsForUnknownWindowsAreIgnored() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        let before = state
        let kinds: [ShellEvent.Kind] = [
            .windowDestroyed(id: 99),
            .windowTitleChanged(id: 99, title: "x"),
            .windowMinimized(id: 99),
            .windowRestored(id: 99),
            .windowFocused(id: 99),
        ]
        for kind in kinds {
            #expect(state.apply(ShellEvent(kind)).isEmpty)
        }
        #expect(state == before)
    }

    @Test func eventsForDeadProcessesAreIgnored() {
        var state = Shell.running(apps: [Shell.app(1)])
        let before = state
        let kinds: [ShellEvent.Kind] = [
            .appTerminated(pid: 9),
            .appActivated(pid: 9),
            .appHidden(pid: 9),
            .appUnhidden(pid: 9),
            .windowCreated(Shell.window(90, 9)),
            .appSnapshot(pid: 9, windows: [Shell.window(90, 9)], reason: .sweep),
        ]
        for kind in kinds {
            #expect(state.apply(ShellEvent(kind)).isEmpty)
        }
        #expect(state == before)
    }

    @Test func duplicateEventsAreHarmless() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        state.apply(ShellEvent(.windowMinimized(id: 10)))
        let once = state
        #expect(state.apply(ShellEvent(.windowMinimized(id: 10))).isEmpty)
        #expect(state.apply(ShellEvent(.windowCreated(Shell.window(10, 1, minimized: true)))).isEmpty)
        #expect(state == once)
        state.apply(ShellEvent(.windowDestroyed(id: 10)))
        let gone = state
        #expect(state.apply(ShellEvent(.windowDestroyed(id: 10))).isEmpty)
        #expect(state == gone)
    }

    @Test func aSweepSnapshotThatDisagreesWinsAndReportsDrift() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1, "Old"), Shell.window(11, 1)])
        let change = state.apply(ShellEvent(.appSnapshot(
            pid: 1,
            windows: [Shell.window(10, 1, "New"), Shell.window(12, 1)],
            reason: .sweep
        )))
        #expect(state.windows.map(\.id) == [10, 12])
        #expect(state.window(id: 10)?.title == "New")
        #expect(change.drift.count == 3)
        #expect(change.windowsAdded == [12])
        #expect(change.windowsRemoved == [11])
    }

    @Test func aSweepThatAgreesReportsNothing() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        let change = state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [Shell.window(10, 1)], reason: .sweep)))
        #expect(change.isEmpty)
    }

    @Test func aLaunchSnapshotFindingWindowsIsNotDrift() {
        var state = Shell.state(.appLaunched(Shell.app(1)))
        let change = state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [Shell.window(10, 1)], reason: .launch)))
        #expect(change.drift.isEmpty)
        #expect(change.windowsAdded == [10])
    }

    @Test func aSnapshotOnlyTouchesItsOwnProcess() {
        var state = Shell.running(apps: [Shell.app(1), Shell.app(2)], windows: [Shell.window(10, 1), Shell.window(20, 2)])
        state.apply(ShellEvent(.appSnapshot(pid: 1, windows: [], reason: .sweep)))
        #expect(state.windows.map(\.id) == [20])
    }

    @Test func onlyOneWindowPerAppIsFocused() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1, focused: true), Shell.window(11, 1)])
        state.apply(ShellEvent(.windowFocused(id: 11)))
        #expect(state.windows.map(\.isFocused) == [false, true])
    }

    @Test func onlyOneAppIsActive() {
        var state = Shell.running(apps: [Shell.app(1, active: true), Shell.app(2)])
        state.apply(ShellEvent(.appActivated(pid: 2)))
        #expect(state.apps.map(\.isActive) == [false, true])
    }

    @Test func aButtonIsActiveOnlyWhenItsAppIsActiveAndItsWindowFocused() {
        var state = Shell.running(apps: [Shell.app(1), Shell.app(2)], windows: [Shell.window(10, 1, focused: true), Shell.window(20, 2)])
        #expect(Shell.buttons(state).map(\.isActive) == [false, false])
        state.apply(ShellEvent(.appActivated(pid: 1)))
        #expect(Shell.buttons(state).map(\.isActive) == [true, false])
        state.apply(ShellEvent(.appActivated(pid: 2)))
        #expect(Shell.buttons(state).map(\.isActive) == [false, false])
    }

    @Test func hidingAndUnhidingAnAppTogglesItsFlag() {
        var state = Shell.running(apps: [Shell.app(1)])
        state.apply(ShellEvent(.appHidden(pid: 1)))
        #expect(state.app(pid: 1)?.isHidden == true)
        state.apply(ShellEvent(.appUnhidden(pid: 1)))
        #expect(state.app(pid: 1)?.isHidden == false)
    }

    @Test func activatingAHiddenAppShowsIt() {
        var state = Shell.running(apps: [Shell.app(1)])
        state.apply(ShellEvent(.appHidden(pid: 1)))
        state.apply(ShellEvent(.appActivated(pid: 1)))
        #expect(state.app(pid: 1)?.isHidden == false)
    }

    @Test func changedBadgesAreReportedAndSameBadgesAreNot() {
        var state = Shell.running(apps: [Shell.app(1)])
        #expect(state.apply(ShellEvent(.badgesRead(["app.1": "3"]))).badgesChanged)
        #expect(state.apply(ShellEvent(.badgesRead(["app.1": "3"]))).isEmpty)
    }

    @Test func changedPinsAreReportedAndSamePinsAreNot() {
        var state = ShellState()
        #expect(state.apply(ShellEvent(.pinsChanged(TaskbarPins(["a"])))).pinsChanged)
        #expect(state.apply(ShellEvent(.pinsChanged(TaskbarPins(["a"])))).isEmpty)
    }

    @Test func aDesktopChangeEventOnlyFlagsTheChange() {
        var state = Shell.running(apps: [Shell.app(1)], windows: [Shell.window(10, 1)])
        let before = state
        var expected = ShellChange()
        expected.desktopChanged = true
        #expect(state.apply(ShellEvent(.desktopChanged)) == expected)
        #expect(state == before)
    }

    @Test func anAppListThatDisagreesWinsAndReportsDrift() {
        var state = Shell.running(apps: [Shell.app(1), Shell.app(2)], windows: [Shell.window(20, 2)])
        let change = state.apply(ShellEvent(.appsRead([Shell.app(1), Shell.app(3)])))
        #expect(state.apps.map(\.pid) == [1, 3])
        #expect(state.windows.isEmpty)
        #expect(change.drift.count == 2)
    }

    @Test func eventsKeepTheTimeTheyWereObserved() {
        #expect(ShellEvent(.desktopChanged, observedAt: 42).observedAt == 42)
    }
}
