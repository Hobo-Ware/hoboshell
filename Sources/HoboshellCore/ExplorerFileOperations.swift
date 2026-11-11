import Foundation

public struct ExplorerTransferResult: Equatable {
    public var created: [URL] = []
    public var failures: [String] = []

    public init(created: [URL] = [], failures: [String] = []) {
        self.created = created
        self.failures = failures
    }
}

public enum ExplorerFileOperations {
    public static func transfer(_ sources: [URL], into folder: URL, operation: TransferOperation) -> ExplorerTransferResult {
        let files = FileManager.default
        var result = ExplorerTransferResult()
        for source in sources {
            let name = source.lastPathComponent
            guard ExplorerDropPolicy.canTransfer(source, into: folder) else {
                result.failures.append(ExplorerFileError.intoItself(name).localizedDescription)
                continue
            }
            if operation == .move, ExplorerDropPolicy.isAlreadyIn(source, folder: folder) {
                continue
            }
            let isFolder = FileEntry.isBrowsableFolder(source)
            let finalName = ExplorerNaming.availableName(for: name, isFolder: isFolder) {
                files.fileExists(atPath: folder.appendingPathComponent($0).path)
            }
            let destination = folder.appendingPathComponent(finalName)
            do {
                if operation == .move {
                    try files.moveItem(at: source, to: destination)
                } else {
                    try files.copyItem(at: source, to: destination)
                }
                result.created.append(destination)
            } catch {
                result.failures.append("\(name): \(error.localizedDescription)")
            }
        }
        return result
    }

    public static func createFolder(in folder: URL) throws -> URL {
        let files = FileManager.default
        let name = ExplorerNaming.newFolderName { files.fileExists(atPath: folder.appendingPathComponent($0).path) }
        let created = folder.appendingPathComponent(name, isDirectory: true)
        try files.createDirectory(at: created, withIntermediateDirectories: false)
        return created
    }

    public static func rename(_ url: URL, to typedName: String) throws -> URL {
        let name = try ExplorerNaming.validate(typedName)
        guard name != url.lastPathComponent else { return url }
        let destination = url.deletingLastPathComponent().appendingPathComponent(name)
        let onlyCaseChanges = name.caseInsensitiveCompare(url.lastPathComponent) == .orderedSame
        if !onlyCaseChanges, FileManager.default.fileExists(atPath: destination.path) {
            throw ExplorerFileError.nameTaken(name)
        }
        try FileManager.default.moveItem(at: url, to: destination)
        return destination
    }
}
