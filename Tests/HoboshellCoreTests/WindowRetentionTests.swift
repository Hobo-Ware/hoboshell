import Foundation
import Testing
@testable import HoboshellCore

@Suite struct WindowRetentionTests {
    private let window = WindowRetention.Known(id: 1, pid: 100)

    private func decide(
        _ retention: inout WindowRetention,
        missing: [WindowRetention.Known]? = nil,
        readable: Set<Int32> = [100],
        running: Set<Int32> = [100],
        destroyed: Set<Int> = [],
        at now: TimeInterval
    ) -> Set<Int> {
        retention.keptIDs(
            missing: missing ?? [window], readablePIDs: readable, runningPIDs: running, destroyed: destroyed, now: now
        )
    }

    @Test func aWindowMissingOnceIsKept() {
        var retention = WindowRetention()
        #expect(decide(&retention, at: 10) == [1])
    }

    @Test func aWindowMissingFromTwoSuccessiveReadsIsDropped() {
        var retention = WindowRetention()
        _ = decide(&retention, at: 10)
        #expect(decide(&retention, at: 11) == [])
    }

    @Test func readsCloserThanTheGapCountAsOneMiss() {
        var retention = WindowRetention()
        _ = decide(&retention, at: 10)
        #expect(decide(&retention, at: 10.1) == [1])
    }

    @Test func aDestroyedWindowIsDroppedAtOnce() {
        var retention = WindowRetention()
        #expect(decide(&retention, destroyed: [1], at: 10) == [])
    }

    @Test func aQuitAppTakesItsWindowsWithIt() {
        var retention = WindowRetention()
        #expect(decide(&retention, running: [], at: 10) == [])
    }

    @Test func anUnreadableAppKeepsItsWindowsAndCountsNoMiss() {
        var retention = WindowRetention()
        _ = decide(&retention, readable: [], at: 10)
        _ = decide(&retention, readable: [], at: 11)
        #expect(decide(&retention, at: 12) == [1])
    }

    @Test func aWindowThatReturnsStartsCountingAgain() {
        var retention = WindowRetention()
        _ = decide(&retention, at: 10)
        _ = decide(&retention, missing: [], at: 11)
        #expect(decide(&retention, at: 12) == [1])
    }

    @Test func eachWindowIsJudgedOnItsOwn() {
        var retention = WindowRetention()
        let other = WindowRetention.Known(id: 2, pid: 100)
        _ = decide(&retention, missing: [window], at: 10)
        #expect(decide(&retention, missing: [window, other], at: 11) == [2])
    }

    @Test func noMissingWindowsKeepsNothing() {
        var retention = WindowRetention()
        #expect(decide(&retention, missing: [], at: 10) == [])
    }
}
