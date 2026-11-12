import Testing
@testable import HoboshellCore

@Suite struct StartNameMatchTests {
    private let names = ["Notes", "Mail", "Keynote", "Pocket Notes", "Numbers"]

    @Test func emptyQueryKeepsEveryNameInOrder() {
        #expect(StartNameMatch.rank(query: "  ", in: names) == [0, 1, 2, 3, 4])
    }

    @Test func prefixMatchesComeFirstThenWordStartsThenInsideMatches() {
        #expect(StartNameMatch.rank(query: "not", in: names) == [0, 3, 2])
    }

    @Test func matchingIgnoresCaseAndAccents() {
        #expect(StartNameMatch.rank(query: "MAIL", in: ["Café", "Mail"]) == [1])
        #expect(StartNameMatch.rank(query: "cafe", in: ["Café", "Mail"]) == [0])
    }

    @Test func nothingMatchesAnUnknownName() {
        #expect(StartNameMatch.rank(query: "zzz", in: names).isEmpty)
    }

    @Test func equalRanksKeepTheirOriginalOrder() {
        #expect(StartNameMatch.rank(query: "n", in: ["Numbers", "Notes", "Nook"]) == [0, 1, 2])
    }
}
