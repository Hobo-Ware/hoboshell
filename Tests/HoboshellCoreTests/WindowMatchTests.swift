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
}
