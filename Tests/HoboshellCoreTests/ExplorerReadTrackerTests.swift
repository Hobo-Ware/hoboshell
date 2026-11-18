import Testing
@testable import HoboshellCore

@Suite struct ExplorerReadTrackerTests {
    @Test func aLoneReloadIsAccepted() {
        var tracker = ExplorerReadTracker()
        let ticket = tracker.beginReload(at: 10)
        let ticketAccepted = tracker.accept(ticket)
        #expect(ticketAccepted)
    }

    @Test func aReloadStartedLaterReplacesAnEarlierOne() {
        var tracker = ExplorerReadTracker()
        let first = tracker.beginReload(at: 10)
        let second = tracker.beginReload(at: 20)
        let firstAccepted = tracker.accept(first)
        #expect(!firstAccepted)
        let secondAccepted = tracker.accept(second)
        #expect(secondAccepted)
    }

    @Test func aLateNavigationReplacesAnEarlierOne() {
        var tracker = ExplorerReadTracker()
        let first = tracker.beginNavigation()
        let second = tracker.beginNavigation()
        let firstAccepted = tracker.accept(first)
        #expect(!firstAccepted)
        let secondAccepted = tracker.accept(second)
        #expect(secondAccepted)
    }

    @Test func aNavigationOutlivesAReloadStartedWhileItWasReading() {
        var tracker = ExplorerReadTracker()
        let navigation = tracker.beginNavigation()
        _ = tracker.beginReload(at: 10)
        let navigationAccepted = tracker.accept(navigation)
        #expect(navigationAccepted)
    }

    @Test func aReloadStartedBeforeANavigationLandedIsDropped() {
        var tracker = ExplorerReadTracker()
        let reload = tracker.beginReload(at: 10)
        let navigation = tracker.beginNavigation()
        let navigationAccepted = tracker.accept(navigation)
        #expect(navigationAccepted)
        let reloadAccepted = tracker.accept(reload)
        #expect(!reloadAccepted)
    }

    @Test func aReloadStartedWhileANavigationWasReadingIsDroppedOnceItLands() {
        var tracker = ExplorerReadTracker()
        let navigation = tracker.beginNavigation()
        let reload = tracker.beginReload(at: 10)
        let navigationAccepted = tracker.accept(navigation)
        #expect(navigationAccepted)
        let reloadAccepted = tracker.accept(reload)
        #expect(!reloadAccepted)
    }

    @Test func aReloadSurvivesANavigationThatNeverLands() {
        var tracker = ExplorerReadTracker()
        let reload = tracker.beginReload(at: 10)
        let navigation = tracker.beginNavigation()
        #expect(tracker.isCurrent(navigation))
        let reloadAccepted = tracker.accept(reload)
        #expect(reloadAccepted)
    }

    @Test func aNavigationIsAcceptedOnlyOnce() {
        var tracker = ExplorerReadTracker()
        let navigation = tracker.beginNavigation()
        _ = tracker.accept(navigation)
        #expect(!tracker.isCurrent(navigation))
    }

    @Test func askingWhetherATicketIsCurrentChangesNothing() {
        var tracker = ExplorerReadTracker()
        let reload = tracker.beginReload(at: 10)
        _ = tracker.isCurrent(reload)
        #expect(tracker.isReloadPending)
    }

    @Test func aReloadIsPendingUntilItsResultIsAccepted() {
        var tracker = ExplorerReadTracker()
        #expect(!tracker.isReloadPending)
        let reload = tracker.beginReload(at: 10)
        #expect(tracker.isReloadPending)
        _ = tracker.accept(reload)
        #expect(!tracker.isReloadPending)
    }

    @Test func aStaleReloadResultLeavesTheNewerOneStillPending() {
        var tracker = ExplorerReadTracker()
        let first = tracker.beginReload(at: 10)
        _ = tracker.beginReload(at: 20)
        _ = tracker.accept(first)
        #expect(tracker.isReloadPending)
    }

    @Test func aLandedNavigationClearsAPendingReloadOfTheOldFolder() {
        var tracker = ExplorerReadTracker()
        _ = tracker.beginReload(at: 10)
        let navigation = tracker.beginNavigation()
        _ = tracker.accept(navigation)
        #expect(!tracker.isReloadPending)
    }

    @Test func aChangeBeforeTheLastReloadStartedIsCovered() {
        var tracker = ExplorerReadTracker()
        _ = tracker.beginReload(at: 100)
        #expect(tracker.isChangeCovered(eventAt: 90))
        #expect(tracker.isChangeCovered(eventAt: 100))
    }

    @Test func aChangeAfterTheLastReloadStartedIsNotCovered() {
        var tracker = ExplorerReadTracker()
        _ = tracker.beginReload(at: 100)
        #expect(!tracker.isChangeCovered(eventAt: 101))
    }

    @Test func noChangeIsCoveredBeforeAnyReloadStarted() {
        let tracker = ExplorerReadTracker()
        #expect(!tracker.isChangeCovered(eventAt: 0))
        #expect(!tracker.isChangeCovered(eventAt: 5))
    }
}
