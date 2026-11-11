import Foundation

public struct FileEntry {
    public let url: URL
    public let isFolder: Bool
    public let modified: Date?
    public let size: Int?
    public let kind: String

    public var name: String { url.lastPathComponent }

    private static let resourceKeys: [URLResourceKey] = [
        .isDirectoryKey,
        .isPackageKey,
        .contentModificationDateKey,
        .fileSizeKey,
        .localizedTypeDescriptionKey,
    ]

    public static func isBrowsableFolder(_ url: URL) -> Bool {
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
        return (values?.isDirectory ?? false) && !(values?.isPackage ?? false)
    }

    public static func contents(of folder: URL) throws -> [FileEntry] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: resourceKeys,
            options: .skipsHiddenFiles
        )
        return urls
            .map { url in
                let values = try? url.resourceValues(forKeys: Set(resourceKeys))
                let isFolder = (values?.isDirectory ?? false) && !(values?.isPackage ?? false)
                return FileEntry(
                    url: url,
                    isFolder: isFolder,
                    modified: values?.contentModificationDate,
                    size: isFolder ? nil : values?.fileSize,
                    kind: values?.localizedTypeDescription ?? ""
                )
            }
            .sorted { first, second in
                if first.isFolder != second.isFolder {
                    return first.isFolder
                }
                return first.name.localizedStandardCompare(second.name) == .orderedAscending
            }
    }
}
