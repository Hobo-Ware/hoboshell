import Testing
@testable import HoboshellCore

@Suite struct WindowRecencyTests {
    @Test func theLastActivatedWindowComesFirst() {
        var recency = WindowRecency()
        recency.activated(1)
        recency.activated(2)
        recency.activated(3)
        #expect(recency.ordered([1, 2, 3]) == [3, 2, 1])
    }

    @Test func activatingAgainMovesAWindowToTheFront() {
        var recency = WindowRecency()
        recency.activated(1)
        recency.activated(2)
        recency.activated(1)
        #expect(recency.ordered([1, 2]) == [1, 2])
    }

    @Test func windowsNeverActivatedFollowInGivenOrder() {
        var recency = WindowRecency()
        recency.activated(2)
        #expect(recency.ordered([5, 2, 4]) == [2, 5, 4])
    }

    @Test func closedWindowsAreLeftOut() {
        var recency = WindowRecency()
        recency.activated(1)
        recency.activated(2)
        #expect(recency.ordered([1]) == [1])
    }

    @Test func forgettingDropsWindowsThatAreGone() {
        var recency = WindowRecency()
        recency.activated(1)
        recency.activated(2)
        recency.forget(keeping: [1])
        recency.activated(2)
        #expect(recency.ordered([1, 2]) == [2, 1])
    }

    @Test func reactivatingTheFrontWindowChangesNothing() {
        var recency = WindowRecency()
        recency.activated(1)
        recency.activated(2)
        recency.activated(2)
        #expect(recency.ordered([1, 2]) == [2, 1])
    }

    @Test func aRefreshedListKeepsTheShownOrderAndAppendsNewWindows() {
        #expect(WindowRecency.keepingOrder(of: [3, 1, 2], among: [1, 4, 3]) == [3, 1, 4])
    }
}
