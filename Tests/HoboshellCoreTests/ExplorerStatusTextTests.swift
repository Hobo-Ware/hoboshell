import Testing
@testable import HoboshellCore

@Suite struct ExplorerStatusTextTests {
    @Test func emptyFolderSaysZeroItems() {
        #expect(ExplorerStatusText.text(itemCount: 0, selection: []) == "0 items")
    }

    @Test func oneItemIsSingular() {
        #expect(ExplorerStatusText.text(itemCount: 1, selection: []) == "1 item")
    }

    @Test func severalItemsArePlural() {
        #expect(ExplorerStatusText.text(itemCount: 12, selection: []) == "12 items")
    }

    @Test func selectionShowsCountAndTotalSize() {
        let selection = [
            ExplorerTestSupport.entry("a", size: 1500),
            ExplorerTestSupport.entry("b", size: 1500),
        ]
        #expect(ExplorerStatusText.text(itemCount: 12, selection: selection) == "12 items - 2 selected, 3 KB")
    }

    @Test func selectingOnlyFoldersShowsNoSize() {
        let selection = [ExplorerTestSupport.entry("f", folder: true)]
        #expect(ExplorerStatusText.text(itemCount: 3, selection: selection) == "3 items - 1 selected")
    }

    @Test func foldersDoNotAddToTheTotal() {
        let selection = [
            ExplorerTestSupport.entry("f", folder: true),
            ExplorerTestSupport.entry("a", size: 2_000_000),
        ]
        #expect(ExplorerStatusText.text(itemCount: 3, selection: selection) == "3 items - 2 selected, 2 MB")
    }
}
