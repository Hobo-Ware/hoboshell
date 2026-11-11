import Testing
@testable import HoboshellCore

@Suite struct FileTypeLabelTests {
    @Test func systemDescriptionWins() {
        #expect(FileTypeLabel.label(isFolder: false, localizedDescription: "PDF document", fileExtension: "pdf") == "PDF document")
    }

    @Test func folderWithoutDescriptionIsFolder() {
        #expect(FileTypeLabel.label(isFolder: true, localizedDescription: nil, fileExtension: "") == "Folder")
    }

    @Test func emptyDescriptionFallsBackToTheExtension() {
        #expect(FileTypeLabel.label(isFolder: false, localizedDescription: "", fileExtension: "xyz") == "XYZ file")
    }

    @Test func noDescriptionAndNoExtensionIsFile() {
        #expect(FileTypeLabel.label(isFolder: false, localizedDescription: nil, fileExtension: "") == "File")
    }
}
