import Foundation
import Testing
@testable import HoboshellCore

@Suite struct ExplorerTypeAheadTests {
    private let names = ["Apple", "apricot", "Banana", "Berry", "cherry"]

    @Test func typingQuicklyBuildsOnePrefix() {
        var typeAhead = ExplorerTypeAhead()
        let start = Date(timeIntervalSince1970: 100)
        #expect(typeAhead.append("b", at: start) == "b")
        #expect(typeAhead.append("e", at: start.addingTimeInterval(0.3)) == "be")
    }

    @Test func pauseStartsAFreshPrefix() {
        var typeAhead = ExplorerTypeAhead()
        let start = Date(timeIntervalSince1970: 100)
        _ = typeAhead.append("b", at: start)
        #expect(typeAhead.append("c", at: start.addingTimeInterval(2)) == "c")
    }

    @Test func matchIgnoresCase() {
        #expect(ExplorerTypeAhead.match(prefix: "BAN", in: names, selected: nil) == 2)
    }

    @Test func singleLetterCyclesThroughMatches() {
        #expect(ExplorerTypeAhead.match(prefix: "a", in: names, selected: nil) == 0)
        #expect(ExplorerTypeAhead.match(prefix: "a", in: names, selected: 0) == 1)
        #expect(ExplorerTypeAhead.match(prefix: "a", in: names, selected: 1) == 0)
    }

    @Test func longerPrefixKeepsTheCurrentRowWhenItStillMatches() {
        #expect(ExplorerTypeAhead.match(prefix: "be", in: names, selected: 3) == 3)
    }

    @Test func noMatchReturnsNil() {
        #expect(ExplorerTypeAhead.match(prefix: "z", in: names, selected: nil) == nil)
    }

    @Test func emptyListOrPrefixReturnsNil() {
        #expect(ExplorerTypeAhead.match(prefix: "a", in: [], selected: nil) == nil)
        #expect(ExplorerTypeAhead.match(prefix: "", in: names, selected: nil) == nil)
    }
}
