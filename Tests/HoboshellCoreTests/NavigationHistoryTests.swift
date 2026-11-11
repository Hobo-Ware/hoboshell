import Foundation
import Testing
@testable import HoboshellCore

@Suite struct NavigationHistoryTests {
    private let a = URL(fileURLWithPath: "/a")
    private let b = URL(fileURLWithPath: "/b")
    private let c = URL(fileURLWithPath: "/c")

    @Test func freshHistoryCannotMove() {
        var history = NavigationHistory(start: a)
        #expect(!history.canGoBack)
        #expect(!history.canGoForward)
        #expect(history.goBack() == nil)
        #expect(history.goForward() == nil)
        #expect(history.current == a)
    }

    @Test func visitingEnablesBack() {
        var history = NavigationHistory(start: a)
        history.visit(b)
        #expect(history.current == b)
        #expect(history.canGoBack)
        #expect(!history.canGoForward)
    }

    @Test func backThenForwardReturnsToTheSamePlace() {
        var history = NavigationHistory(start: a)
        history.visit(b)
        #expect(history.goBack() == a)
        #expect(history.canGoForward)
        #expect(history.goForward() == b)
        #expect(history.current == b)
    }

    @Test func visitingAfterBackDropsTheForwardTrail() {
        var history = NavigationHistory(start: a)
        history.visit(b)
        history.goBack()
        history.visit(c)
        #expect(!history.canGoForward)
        #expect(history.goBack() == a)
    }

    @Test func visitingTheCurrentFolderWithATrailingSlashChangesNothing() {
        var history = NavigationHistory(start: URL(fileURLWithPath: "/a", isDirectory: true))
        history.visit(URL(fileURLWithPath: "/a/", isDirectory: false))
        #expect(!history.canGoBack)
    }

    @Test func visitingTheCurrentFolderChangesNothing() {
        var history = NavigationHistory(start: a)
        history.visit(a)
        #expect(!history.canGoBack)
    }
}
