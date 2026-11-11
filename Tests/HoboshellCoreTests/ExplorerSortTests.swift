import Testing
@testable import HoboshellCore

@Suite struct ExplorerSortTests {
    private let sample = [
        ExplorerTestSupport.entry("b.txt", modified: 20, size: 5, kind: "Text"),
        ExplorerTestSupport.entry("a10.txt", modified: 30, size: 50, kind: "Text"),
        ExplorerTestSupport.entry("a2.png", modified: 10, size: 500, kind: "Image"),
        ExplorerTestSupport.entry("zeta", folder: true, modified: 40, kind: "Folder"),
        ExplorerTestSupport.entry("alpha", folder: true, modified: 5, kind: "Folder"),
    ]

    @Test func nameAscendingPutsFoldersFirstInNaturalOrder() {
        let sorted = ExplorerSort(column: .name, ascending: true).apply(to: sample)
        #expect(sorted.map(\.name) == ["alpha", "zeta", "a2.png", "a10.txt", "b.txt"])
    }

    @Test func nameDescendingReversesWithinGroupsAndKeepsFoldersFirst() {
        let sorted = ExplorerSort(column: .name, ascending: false).apply(to: sample)
        #expect(sorted.map(\.name) == ["zeta", "alpha", "b.txt", "a10.txt", "a2.png"])
    }

    @Test func sizeSortsFilesBySizeAndFoldersByName() {
        let sorted = ExplorerSort(column: .size, ascending: true).apply(to: sample)
        #expect(sorted.map(\.name) == ["alpha", "zeta", "b.txt", "a10.txt", "a2.png"])
    }

    @Test func sizeDescendingKeepsFoldersFirst() {
        let sorted = ExplorerSort(column: .size, ascending: false).apply(to: sample)
        #expect(sorted.map(\.name) == ["alpha", "zeta", "a2.png", "a10.txt", "b.txt"])
    }

    @Test func modifiedSortsOldestFirstWhenAscending() {
        let sorted = ExplorerSort(column: .modified, ascending: true).apply(to: sample)
        #expect(sorted.map(\.name) == ["alpha", "zeta", "a2.png", "b.txt", "a10.txt"])
    }

    @Test func kindSortsByLabelThenName() {
        let sorted = ExplorerSort(column: .kind, ascending: true).apply(to: sample)
        #expect(sorted.map(\.name) == ["alpha", "zeta", "a2.png", "a10.txt", "b.txt"])
    }

    @Test func missingDatesSortBeforeEverythingElse() {
        let entries = [
            ExplorerTestSupport.entry("dated", modified: 1),
            ExplorerTestSupport.entry("undated"),
        ]
        let sorted = ExplorerSort(column: .modified, ascending: true).apply(to: entries)
        #expect(sorted.map(\.name) == ["undated", "dated"])
    }

    @Test func emptyInputStaysEmpty() {
        #expect(ExplorerSort.standard.apply(to: []).isEmpty)
    }

    @Test func choosingTheSameColumnFlipsTheDirection() {
        let flipped = ExplorerSort(column: .size, ascending: true).choosing(.size)
        #expect(flipped == ExplorerSort(column: .size, ascending: false))
    }

    @Test func choosingAnotherColumnStartsAscending() {
        let chosen = ExplorerSort(column: .size, ascending: false).choosing(.name)
        #expect(chosen == ExplorerSort(column: .name, ascending: true))
    }
}
