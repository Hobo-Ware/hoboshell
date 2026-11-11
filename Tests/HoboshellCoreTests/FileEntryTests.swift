import Foundation
import Testing
@testable import HoboshellCore

@Suite struct FileEntryTests {
    private func makeFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("hoboshell-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        return folder
    }

    @Test func listsFoldersFirstThenFilesInNaturalOrder() throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        for name in ["b.txt", "a10.txt", "a2.txt", ".hidden"] {
            try Data("x".utf8).write(to: folder.appendingPathComponent(name))
        }
        try FileManager.default.createDirectory(at: folder.appendingPathComponent("zeta"), withIntermediateDirectories: false)

        let entries = try FileEntry.contents(of: folder)

        #expect(entries.map(\.name) == ["zeta", "a2.txt", "a10.txt", "b.txt"])
        #expect(entries.map(\.isFolder) == [true, false, false, false])
        #expect(entries[0].size == nil)
        #expect(entries[1].size == 1)
    }

    @Test func appBundleIsAFileNotAFolder() throws {
        let folder = try makeFolder()
        defer { try? FileManager.default.removeItem(at: folder) }
        let bundle = folder.appendingPathComponent("Thing.app")
        try FileManager.default.createDirectory(at: bundle, withIntermediateDirectories: false)

        #expect(!FileEntry.isBrowsableFolder(bundle))
        #expect(FileEntry.isBrowsableFolder(folder))
        #expect(try FileEntry.contents(of: folder).map(\.isFolder) == [false])
    }

    @Test func missingFolderThrows() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("hoboshell-missing-\(UUID().uuidString)")
        #expect(throws: (any Error).self) {
            try FileEntry.contents(of: missing)
        }
    }
}
