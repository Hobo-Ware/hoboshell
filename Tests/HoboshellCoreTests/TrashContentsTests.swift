import Testing
@testable import HoboshellCore

@Suite struct TrashContentsTests {
    @Test func noEntriesMeansEmpty() {
        let contents = TrashContents(entryNames: [])
        #expect(contents == .empty)
        #expect(!contents.isFull)
        #expect(contents.countText == nil)
    }

    @Test func entriesMeanItems() {
        let contents = TrashContents(entryNames: ["a.txt", "b.txt"])
        #expect(contents == .items(2))
        #expect(contents.isFull)
        #expect(contents.countText == "2 items")
    }

    @Test func oneItemUsesTheSingularCountText() {
        #expect(TrashContents(entryNames: ["a.txt"]).countText == "1 item")
    }

    @Test func anUnreadableTrashCannotBeBrowsed() {
        #expect(!TrashContents(entryNames: nil).canBrowse)
    }

    @Test func aReadableEmptyTrashCanBeBrowsed() {
        #expect(TrashContents(entryNames: []).canBrowse)
    }

    @Test func hiddenEntriesDoNotMakeTheTrashFull() {
        #expect(TrashContents(entryNames: [".DS_Store"]) == .empty)
    }

    @Test func hiddenEntriesAreNotCounted() {
        #expect(TrashContents(entryNames: [".DS_Store", "a.txt"]) == .items(1))
    }

    @Test func aFolderThatCannotBeListedIsUnreadable() {
        let contents = TrashContents(entryNames: nil)
        #expect(contents == .unreadable)
        #expect(!contents.isFull)
        #expect(contents.countText == nil)
    }
}
