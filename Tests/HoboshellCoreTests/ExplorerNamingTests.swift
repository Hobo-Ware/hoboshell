import Testing
@testable import HoboshellCore

@Suite struct ExplorerNamingTests {
    @Test func freeNameIsKept() {
        #expect(ExplorerNaming.availableName(for: "a.txt", isFolder: false) { _ in false } == "a.txt")
    }

    @Test func clashAddsCopyBeforeTheExtension() {
        let taken: Set<String> = ["report.txt"]
        #expect(ExplorerNaming.availableName(for: "report.txt", isFolder: false) { taken.contains($0) } == "report copy.txt")
    }

    @Test func secondClashCountsUp() {
        let taken: Set<String> = ["report.txt", "report copy.txt"]
        #expect(ExplorerNaming.availableName(for: "report.txt", isFolder: false) { taken.contains($0) } == "report copy 2.txt")
    }

    @Test func folderNamesWithDotsAreNotSplit() {
        let taken: Set<String> = ["v1.2"]
        #expect(ExplorerNaming.availableName(for: "v1.2", isFolder: true) { taken.contains($0) } == "v1.2 copy")
    }

    @Test func dotFilesGetCopyAtTheEnd() {
        let taken: Set<String> = [".profile"]
        #expect(ExplorerNaming.availableName(for: ".profile", isFolder: false) { taken.contains($0) } == ".profile copy")
    }

    @Test func onlyTheLastExtensionIsKeptAside() {
        let taken: Set<String> = ["a.tar.gz"]
        #expect(ExplorerNaming.availableName(for: "a.tar.gz", isFolder: false) { taken.contains($0) } == "a.tar copy.gz")
    }

    @Test func newFolderStartsPlain() {
        #expect(ExplorerNaming.newFolderName { _ in false } == "New folder")
    }

    @Test func newFolderCountsUpOnClash() {
        let taken: Set<String> = ["New folder", "New folder (2)"]
        #expect(ExplorerNaming.newFolderName { taken.contains($0) } == "New folder (3)")
    }

    @Test func validNameIsTrimmed() throws {
        #expect(try ExplorerNaming.validate("  notes.txt \n") == "notes.txt")
    }

    @Test func emptyNameIsRejected() {
        #expect(throws: ExplorerFileError.emptyName) { try ExplorerNaming.validate("   ") }
    }

    @Test func slashAndColonAreRejected() {
        #expect(throws: ExplorerFileError.invalidName("a/b")) { try ExplorerNaming.validate("a/b") }
        #expect(throws: ExplorerFileError.invalidName("a:b")) { try ExplorerNaming.validate("a:b") }
    }

    @Test func dotNamesAreRejected() {
        #expect(throws: ExplorerFileError.invalidName("..")) { try ExplorerNaming.validate("..") }
    }

    @Test func overlongNameIsRejected() {
        #expect(throws: ExplorerFileError.nameTooLong) { try ExplorerNaming.validate(String(repeating: "a", count: 300)) }
    }

    @Test func renameSelectionStopsBeforeTheExtension() {
        #expect(ExplorerNaming.stemLength(of: "report.txt", isFolder: false) == 6)
    }

    @Test func renameSelectionCoversAWholeFolderName() {
        #expect(ExplorerNaming.stemLength(of: "v1.2", isFolder: true) == 4)
    }

    @Test func renameSelectionCoversAWholeDotFileName() {
        #expect(ExplorerNaming.stemLength(of: ".profile", isFolder: false) == 8)
    }
}
