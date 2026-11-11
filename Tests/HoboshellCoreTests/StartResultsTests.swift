import Testing
@testable import HoboshellCore

@Suite struct StartResultsTests {
    @Test func groupsKeepTheOrderAppsFilesSettings() {
        #expect(StartResults.groups(apps: 2, files: 3, settings: 1).map(\.kind) == [.apps, .files, .settings])
    }

    @Test func emptyGroupsAreLeftOut() {
        #expect(StartResults.groups(apps: 0, files: 2, settings: 0) == [StartResultGroup(kind: .files, count: 2)])
    }

    @Test func eachGroupIsCappedAtItsLimit() {
        let groups = StartResults.groups(apps: 50, files: 50, settings: 50)
        #expect(groups.map(\.count) == [8, 8, 5])
    }

    @Test func noResultsMakeNoGroups() {
        #expect(StartResults.groups(apps: 0, files: 0, settings: 0).isEmpty)
    }

    @Test func theTopHitIsTheFirstItemOfTheFirstGroup() {
        let sections = StartResults.sections(of: StartResults.groups(apps: 0, files: 2, settings: 1))
        #expect(StartNavigation.first(in: sections) == StartPosition(section: 0, index: 0))
    }

    @Test func fileSearchWaitsForTwoCharacters() {
        #expect(!StartResults.allowsFileSearch(for: " a "))
        #expect(StartResults.allowsFileSearch(for: "ab"))
    }
}
