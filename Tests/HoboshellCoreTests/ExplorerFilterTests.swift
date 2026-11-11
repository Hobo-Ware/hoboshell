import Testing
@testable import HoboshellCore

@Suite struct ExplorerFilterTests {
    private let sample = [
        ExplorerTestSupport.entry("Report.pdf"),
        ExplorerTestSupport.entry("notes.txt"),
        ExplorerTestSupport.entry("Café menu.md"),
    ]

    @Test func emptyQueryKeepsEverything() {
        #expect(ExplorerFilter.apply(to: sample, query: "").count == 3)
    }

    @Test func blankQueryKeepsEverything() {
        #expect(ExplorerFilter.apply(to: sample, query: "   ").count == 3)
    }

    @Test func matchIgnoresCase() {
        #expect(ExplorerFilter.apply(to: sample, query: "REPORT").map(\.name) == ["Report.pdf"])
    }

    @Test func matchFindsTextInTheMiddleOfTheName() {
        #expect(ExplorerFilter.apply(to: sample, query: "otes").map(\.name) == ["notes.txt"])
    }

    @Test func matchIgnoresAccents() {
        #expect(ExplorerFilter.apply(to: sample, query: "cafe").map(\.name) == ["Café menu.md"])
    }

    @Test func noMatchGivesAnEmptyList() {
        #expect(ExplorerFilter.apply(to: sample, query: "zzz").isEmpty)
    }
}
