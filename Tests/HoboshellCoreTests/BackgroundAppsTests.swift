import Foundation
import Testing
@testable import HoboshellCore

@Suite struct BackgroundAppsTests {
    private func chat(windows: Int = 0, readable: Bool = true, pid: Int32 = 10) -> BackgroundApps.Candidate {
        BackgroundApps.Candidate(id: "chat", pid: pid, windowCount: windows, windowsReadable: readable)
    }

    @Test func anAppWithNoWindowIsNotBackgroundUntilItHasSettled() {
        var apps = BackgroundApps()
        #expect(apps.settledWindowless([chat()], now: 10) == [])
        #expect(apps.settledWindowless([chat()], now: 10 + BackgroundApps.settleDelay - 0.1) == [])
        #expect(apps.settledWindowless([chat()], now: 10 + BackgroundApps.settleDelay) == ["chat"])
    }

    @Test func anAppWithAWindowIsNeverBackground() {
        var apps = BackgroundApps()
        _ = apps.settledWindowless([chat()], now: 10)
        #expect(apps.settledWindowless([chat(windows: 1)], now: 20) == [])
    }

    @Test func aWindowAppearingRestartsTheSettleClock() {
        var apps = BackgroundApps()
        _ = apps.settledWindowless([chat()], now: 10)
        _ = apps.settledWindowless([chat(windows: 1)], now: 11)
        #expect(apps.settledWindowless([chat()], now: 12) == [])
    }

    @Test func anAppWhoseWindowsCannotBeReadIsNeverBackground() {
        var apps = BackgroundApps()
        _ = apps.settledWindowless([chat(readable: false)], now: 10)
        #expect(apps.settledWindowless([chat(readable: false)], now: 30) == [])
    }

    @Test func aQuitAppForgetsItsClock() {
        var apps = BackgroundApps()
        _ = apps.settledWindowless([chat()], now: 10)
        _ = apps.settledWindowless([], now: 11)
        #expect(apps.settledWindowless([chat()], now: 12) == [])
    }

    @Test func aRelaunchedAppUnderANewProcessStartsAgain() {
        var apps = BackgroundApps()
        _ = apps.settledWindowless([chat(pid: 10)], now: 10)
        #expect(apps.settledWindowless([chat(pid: 11)], now: 12) == [])
    }

    @Test func pinnedAndExcludedAppsStayOutOfTheTray() {
        let ids = BackgroundApps.trayIDs(
            windowless: ["finder", "mail", "chat", "notes"],
            pinned: TaskbarPins(["mail"]),
            excluded: ["finder"]
        )
        #expect(ids == ["chat", "notes"])
    }

    @Test func trayOrderFollowsTheInputAndDropsRepeats() {
        let ids = BackgroundApps.trayIDs(windowless: ["b", "a", "b"], pinned: TaskbarPins(), excluded: [])
        #expect(ids == ["b", "a"])
    }

    @Test func threeAppsAllShowInline() {
        let split = BackgroundApps.split(["a", "b", "c"])
        #expect(split.inline == ["a", "b", "c"])
        #expect(!split.opensFlyout)
    }

    @Test func fourAppsShowThreeAndOpenTheFlyout() {
        let split = BackgroundApps.split(["a", "b", "c", "d"])
        #expect(split.inline == ["a", "b", "c"])
        #expect(split.opensFlyout)
    }

    @Test func noAppsShowNothing() {
        let split = BackgroundApps.split([String]())
        #expect(split.inline.isEmpty)
        #expect(!split.opensFlyout)
    }
}
