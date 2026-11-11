import Foundation
import Testing
@testable import HoboshellCore

@Suite struct ExplorerPathInputTests {
    private let home = URL(fileURLWithPath: "/Users/me")
    private let current = URL(fileURLWithPath: "/Users/me/Documents")

    @Test func absolutePathIsKept() {
        #expect(ExplorerPathInput.resolve("/Applications", home: home, current: current)?.path == "/Applications")
    }

    @Test func tildeMeansHome() {
        #expect(ExplorerPathInput.resolve("~", home: home, current: current)?.path == "/Users/me")
        #expect(ExplorerPathInput.resolve("~/Pictures", home: home, current: current)?.path == "/Users/me/Pictures")
    }

    @Test func relativePathStartsInTheCurrentFolder() {
        #expect(ExplorerPathInput.resolve("Taxes/2025", home: home, current: current)?.path == "/Users/me/Documents/Taxes/2025")
    }

    @Test func dotsAndTrailingSlashesAreCleanedUp() {
        #expect(ExplorerPathInput.resolve(" /Users/me/../you/ ", home: home, current: current)?.path == "/Users/you")
    }

    @Test func blankTextGivesNothing() {
        #expect(ExplorerPathInput.resolve("   ", home: home, current: current) == nil)
    }

    @Test func nearestExistingFolderWalksUpToSomethingThatExists() {
        let existing: Set<String> = ["/Users", "/Users/me"]
        let found = ExplorerPathInput.nearestExistingFolder(from: URL(fileURLWithPath: "/Users/me/gone/deeper")) {
            existing.contains($0.path)
        }
        #expect(found.path == "/Users/me")
    }

    @Test func nearestExistingFolderStopsAtTheRoot() {
        let found = ExplorerPathInput.nearestExistingFolder(from: URL(fileURLWithPath: "/nothing/here")) { _ in false }
        #expect(found.path == "/")
    }
}
