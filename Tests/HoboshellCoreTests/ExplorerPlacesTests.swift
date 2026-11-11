import Foundation
import Testing
@testable import HoboshellCore

@Suite struct ExplorerPlacesTests {
    private let home = URL(fileURLWithPath: "/Users/me")
    private let applications = URL(fileURLWithPath: "/Applications")

    @Test func listsEveryQuickAccessFolderThatExists() {
        let places = ExplorerPlaces.quickAccess(home: home, applications: applications) { _ in true }
        #expect(places.map(\.name) == ["Home", "Desktop", "Documents", "Downloads", "Pictures", "Music", "Movies", "Applications"])
        #expect(places[1].url.path == "/Users/me/Desktop")
    }

    @Test func skipsFoldersThatAreMissing() {
        let missing: Set<String> = ["/Users/me/Music", "/Users/me/Movies"]
        let places = ExplorerPlaces.quickAccess(home: home, applications: applications) { !missing.contains($0.path) }
        #expect(places.map(\.name) == ["Home", "Desktop", "Documents", "Downloads", "Pictures", "Applications"])
    }

    @Test func nothingExistingGivesAnEmptyList() {
        #expect(ExplorerPlaces.quickAccess(home: home, applications: applications) { _ in false }.isEmpty)
    }
}
