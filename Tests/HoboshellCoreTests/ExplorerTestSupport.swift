import Foundation
@testable import HoboshellCore

enum ExplorerTestSupport {
    static func makeFolder() throws -> URL {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("hoboshell-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false)
        return folder
    }

    static func entry(
        _ name: String,
        folder: Bool = false,
        modified: TimeInterval? = nil,
        size: Int? = nil,
        kind: String = ""
    ) -> FileEntry {
        FileEntry(
            url: URL(fileURLWithPath: "/tmp/\(name)"),
            isFolder: folder,
            modified: modified.map { Date(timeIntervalSince1970: $0) },
            size: size,
            kind: kind
        )
    }
}
