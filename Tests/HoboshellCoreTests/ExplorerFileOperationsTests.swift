import Foundation
import Testing
@testable import HoboshellCore

@Suite struct ExplorerFileOperationsTests {
    private func write(_ name: String, in folder: URL, text: String = "x") throws -> URL {
        let url = folder.appendingPathComponent(name)
        try Data(text.utf8).write(to: url)
        return url
    }

    private func names(in folder: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: folder.path).sorted()
    }

    @Test func copyIntoAnotherFolderKeepsTheOriginal() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try write("a.txt", in: root)
        let target = root.appendingPathComponent("target")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)

        let result = ExplorerFileOperations.transfer([source], into: target, operation: .copy)

        #expect(result.created == [target.appendingPathComponent("a.txt")])
        #expect(try names(in: root) == ["a.txt", "target"])
        #expect(try names(in: target) == ["a.txt"])
    }

    @Test func moveRemovesTheOriginal() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try write("a.txt", in: root)
        let target = root.appendingPathComponent("target")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)

        let result = ExplorerFileOperations.transfer([source], into: target, operation: .move)

        #expect(result.failures.isEmpty)
        #expect(try names(in: root) == ["target"])
        #expect(try names(in: target) == ["a.txt"])
    }

    @Test func pastingIntoTheSameFolderMakesACopyName() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try write("a.txt", in: root)

        let first = ExplorerFileOperations.transfer([source], into: root, operation: .copy)
        let second = ExplorerFileOperations.transfer([source], into: root, operation: .copy)

        #expect(first.created.map(\.lastPathComponent) == ["a copy.txt"])
        #expect(second.created.map(\.lastPathComponent) == ["a copy 2.txt"])
    }

    @Test func clashNeverOverwritesTheExistingFile() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let other = root.appendingPathComponent("other")
        try FileManager.default.createDirectory(at: other, withIntermediateDirectories: false)
        let source = try write("a.txt", in: root, text: "new")
        _ = try write("a.txt", in: other, text: "old")

        _ = ExplorerFileOperations.transfer([source], into: other, operation: .copy)

        #expect(try String(contentsOf: other.appendingPathComponent("a.txt")) == "old")
        #expect(try String(contentsOf: other.appendingPathComponent("a copy.txt")) == "new")
    }

    @Test func movingIntoTheFolderItAlreadyIsInDoesNothing() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try write("a.txt", in: root)

        let result = ExplorerFileOperations.transfer([source], into: root, operation: .move)

        #expect(result == ExplorerTransferResult())
        #expect(try names(in: root) == ["a.txt"])
    }

    @Test func folderIntoItselfIsReportedNotAttempted() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("f")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)

        let result = ExplorerFileOperations.transfer([folder], into: folder, operation: .copy)

        #expect(result.created.isEmpty)
        #expect(result.failures == [ExplorerFileError.intoItself("f").localizedDescription])
    }

    @Test func oneMissingSourceDoesNotStopTheOthers() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let good = try write("a.txt", in: root)
        let missing = root.appendingPathComponent("ghost.txt")
        let target = root.appendingPathComponent("target")
        try FileManager.default.createDirectory(at: target, withIntermediateDirectories: false)

        let result = ExplorerFileOperations.transfer([missing, good], into: target, operation: .copy)

        #expect(result.created.map(\.lastPathComponent) == ["a.txt"])
        #expect(result.failures.count == 1)
        #expect(result.failures[0].hasPrefix("ghost.txt: "))
    }

    @Test func copiedFoldersBringTheirContents() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let folder = root.appendingPathComponent("f")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        _ = try write("inner.txt", in: folder)

        let result = ExplorerFileOperations.transfer([folder], into: root, operation: .copy)

        #expect(try names(in: root.appendingPathComponent("f copy")) == ["inner.txt"])
        #expect(result.created.map(\.lastPathComponent) == ["f copy"])
    }

    @Test func newFolderGetsCountedNames() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }

        let first = try ExplorerFileOperations.createFolder(in: root)
        let second = try ExplorerFileOperations.createFolder(in: root)

        #expect(first.lastPathComponent == "New folder")
        #expect(second.lastPathComponent == "New folder (2)")
    }

    @Test func newFolderInAMissingFolderThrows() {
        let missing = FileManager.default.temporaryDirectory.appendingPathComponent("hoboshell-missing-\(UUID().uuidString)")
        #expect(throws: (any Error).self) { try ExplorerFileOperations.createFolder(in: missing) }
    }

    @Test func renameMovesTheItemToTheNewName() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try write("a.txt", in: root)

        let renamed = try ExplorerFileOperations.rename(source, to: " b.txt ")

        #expect(renamed.lastPathComponent == "b.txt")
        #expect(try names(in: root) == ["b.txt"])
    }

    @Test func renameToTheSameNameChangesNothing() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try write("a.txt", in: root)

        #expect(try ExplorerFileOperations.rename(source, to: "a.txt") == source)
    }

    @Test func renameOntoAnExistingNameIsRefused() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try write("a.txt", in: root)
        _ = try write("b.txt", in: root)

        #expect(throws: ExplorerFileError.nameTaken("b.txt")) { try ExplorerFileOperations.rename(source, to: "b.txt") }
        #expect(try names(in: root) == ["a.txt", "b.txt"])
    }

    @Test func renameWithABadNameIsRefused() throws {
        let root = try ExplorerTestSupport.makeFolder()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = try write("a.txt", in: root)

        #expect(throws: ExplorerFileError.invalidName("x/y")) { try ExplorerFileOperations.rename(source, to: "x/y") }
    }
}
