import Foundation
import Testing
@testable import HoboshellCore

@Suite struct NavigationRequestsTests {
    private static let home = URL(fileURLWithPath: "/home")
    private static let docs = URL(fileURLWithPath: "/home/docs")
    private static let photos = URL(fileURLWithPath: "/home/docs/photos")

    private static func deepHistory() -> NavigationHistory {
        var history = NavigationHistory(start: home)
        history.visit(docs)
        history.visit(photos)
        return history
    }

    @Test func withNothingRequestedTheAppliedHistoryIsTheBase() {
        let requests = NavigationRequests()
        let base = requests.base(applied: Self.deepHistory())
        #expect(base.current == Self.photos)
    }

    @Test func twoBackClicksBeforeTheFirstReadLandsGoTwoSteps() {
        let applied = Self.deepHistory()
        var requests = NavigationRequests()
        var first = requests.base(applied: applied)
        first.goBack()
        requests.request(first)
        var second = requests.base(applied: applied)
        second.goBack()
        requests.request(second)
        #expect(second.current == Self.home)
    }

    @Test func aBackThenAForwardReturnsToWhereTheUserStarted() {
        let applied = Self.deepHistory()
        var requests = NavigationRequests()
        var back = requests.base(applied: applied)
        back.goBack()
        requests.request(back)
        var forward = requests.base(applied: applied)
        forward.goForward()
        #expect(forward.current == Self.photos)
    }

    @Test func aSettledRequestGoesBackToTheAppliedHistory() {
        let applied = Self.deepHistory()
        var requests = NavigationRequests()
        var back = requests.base(applied: applied)
        back.goBack()
        requests.request(back)
        requests.settle()
        let base = requests.base(applied: applied)
        #expect(base.current == Self.photos)
    }
}
