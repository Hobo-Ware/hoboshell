import Foundation

public struct FileEntry: Equatable {
    public let url: URL
    public let isFolder: Bool
    public let modified: Date?
    public let size: Int?
    public let kind: String

    public init(url: URL, isFolder: Bool, modified: Date?, size: Int?, kind: String) {
        self.url = url
        self.isFolder = isFolder
        self.modified = modified
        self.size = size
        self.kind = kind
    }

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

    public static func contents(
        of folder: URL,
        showHidden: Bool = false,
        sort: ExplorerSort = .standard
    ) throws -> [FileEntry] {
        let urls = try FileManager.default.contentsOfDirectory(
            at: folder,
            includingPropertiesForKeys: resourceKeys,
            options: showHidden ? [] : .skipsHiddenFiles
        )
        let entries = urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(resourceKeys))
            let isFolder = (values?.isDirectory ?? false) && !(values?.isPackage ?? false)
            return FileEntry(
                url: url,
                isFolder: isFolder,
                modified: values?.contentModificationDate,
                size: isFolder ? nil : values?.fileSize,
                kind: FileTypeLabel.label(
                    isFolder: isFolder,
                    localizedDescription: values?.localizedTypeDescription,
                    fileExtension: url.pathExtension
                )
            )
        }
        return sort.apply(to: entries)
    }
}
