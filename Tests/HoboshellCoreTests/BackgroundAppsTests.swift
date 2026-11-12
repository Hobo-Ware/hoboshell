import Testing
@testable import HoboshellCore

@Suite struct BackgroundAppsTests {
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
