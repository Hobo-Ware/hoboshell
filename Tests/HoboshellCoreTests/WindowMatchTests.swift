import CoreGraphics
import Testing
@testable import HoboshellCore

@Suite struct WindowMatchTests {
    private let frame = CGRect(x: 100, y: 80, width: 800, height: 600)

    @Test func exactFrameIsFound() {
        let candidates = [CGRect(x: 0, y: 0, width: 800, height: 600), frame]
        #expect(WindowMatch.closestIndex(to: frame, among: candidates, tolerance: 4) == 1)
    }

    @Test func frameOffByAPointStillMatches() {
        let candidates = [CGRect(x: 101, y: 80, width: 799, height: 600)]
        #expect(WindowMatch.closestIndex(to: frame, among: candidates, tolerance: 4) == 0)
    }

    @Test func closestOfTwoNearFramesWins() {
        let candidates = [CGRect(x: 103, y: 80, width: 800, height: 600), CGRect(x: 101, y: 80, width: 800, height: 600)]
        #expect(WindowMatch.closestIndex(to: frame, among: candidates, tolerance: 4) == 1)
    }

    @Test func farFrameIsNotAMatch() {
        let candidates = [CGRect(x: 400, y: 80, width: 800, height: 600)]
        #expect(WindowMatch.closestIndex(to: frame, among: candidates, tolerance: 4) == nil)
    }

    @Test func noCandidatesGivesNoMatch() {
        #expect(WindowMatch.closestIndex(to: frame, among: [], tolerance: 4) == nil)
    }

    private func resolve(
        frame: CGRect? = CGRect(x: 100, y: 80, width: 800, height: 600),
        title: String = "Docs",
        _ candidates: [WindowCandidate]
    ) -> WindowMatchOutcome {
        WindowMatch.resolve(frame: frame, title: title, among: candidates, tolerance: 4)
    }

    @Test func resolveMatchesByFrameFirst() {
        let candidates = [
            WindowCandidate(frame: CGRect(x: 0, y: 0, width: 300, height: 300), title: "Docs"),
            WindowCandidate(frame: frame, title: "Other"),
        ]
        #expect(resolve(candidates) == .match(index: 1, method: .frame))
    }

    @Test func resolveFallsBackToTheTitleWhenTheFrameMoved() {
        let candidates = [
            WindowCandidate(frame: CGRect(x: 0, y: 0, width: 300, height: 300), title: "Mail"),
            WindowCandidate(frame: CGRect(x: 500, y: 0, width: 300, height: 300), title: "Docs"),
        ]
        #expect(resolve(candidates) == .match(index: 1, method: .title))
    }

    @Test func resolveBreaksATitleTieByTheNearerFrame() {
        let candidates = [
            WindowCandidate(frame: CGRect(x: 900, y: 0, width: 300, height: 300), title: "Docs"),
            WindowCandidate(frame: CGRect(x: 120, y: 80, width: 700, height: 500), title: "Docs"),
        ]
        #expect(resolve(candidates) == .match(index: 1, method: .title))
    }

    @Test func resolveUsesTheOnlyNormalWindowWhenFrameAndTitleFail() {
        let candidates = [
            WindowCandidate(frame: CGRect(x: 0, y: 0, width: 300, height: 300), title: "", isNormal: false),
            WindowCandidate(frame: CGRect(x: 500, y: 0, width: 300, height: 300), title: "Renamed"),
        ]
        #expect(resolve(candidates) == .match(index: 1, method: .onlyWindow))
    }

    @Test func resolveRefusesToGuessBetweenSeveralWindows() {
        let candidates = [
            WindowCandidate(frame: CGRect(x: 0, y: 0, width: 300, height: 300), title: "A"),
            WindowCandidate(frame: CGRect(x: 500, y: 0, width: 300, height: 300), title: "B"),
        ]
        #expect(resolve(candidates) == .failure(.ambiguous))
    }

    @Test func resolveIgnoresWindowsThatAreNotNormal() {
        let candidates = [WindowCandidate(frame: frame, title: "Docs", isNormal: false)]
        #expect(resolve(candidates) == .failure(.noNormalWindows))
    }

    @Test func resolveReportsAnAppWithNoWindows() {
        #expect(resolve([]) == .failure(.noWindows))
    }

    @Test func resolveWorksWithoutAFrame() {
        let candidates = [WindowCandidate(frame: frame, title: "Docs")]
        #expect(resolve(frame: nil, title: "Docs", candidates) == .match(index: 0, method: .title))
    }
}
