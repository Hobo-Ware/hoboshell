import Testing
@testable import HoboshellCore

@Suite struct StartFileFilterTests {
    private let home = "/Users/me"

    @Test func filesInsideTheHomeFolderAreListed() {
        #expect(StartFileFilter.isListable(path: "/Users/me/Documents/plan.pdf", home: home))
    }

    @Test func filesOutsideTheHomeFolderAreNot() {
        #expect(!StartFileFilter.isListable(path: "/Users/other/plan.pdf", home: home))
        #expect(!StartFileFilter.isListable(path: "/Users/me2/plan.pdf", home: home))
    }

    @Test func theLibraryFolderIsHidden() {
        #expect(!StartFileFilter.isListable(path: "/Users/me/Library/Caches/a.db", home: home))
    }

    @Test func aLibraryFolderDeeperDownIsStillListed() {
        #expect(StartFileFilter.isListable(path: "/Users/me/Documents/Library/a.txt", home: home))
    }

    @Test func hiddenFilesAndFilesInHiddenFoldersAreNot() {
        #expect(!StartFileFilter.isListable(path: "/Users/me/.zshrc", home: home))
        #expect(!StartFileFilter.isListable(path: "/Users/me/.config/a.txt", home: home))
    }

    @Test func appBundlesAreNot() {
        #expect(!StartFileFilter.isListable(path: "/Users/me/Applications/Foo.app", home: home))
    }

    @Test func theHomeFolderItselfIsNot() {
        #expect(!StartFileFilter.isListable(path: "/Users/me", home: home))
    }
}
