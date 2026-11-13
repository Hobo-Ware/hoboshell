import Foundation

public enum TransferOperation: Equatable {
    case move
    case copy
}

public enum ExplorerDropPolicy {
    public static func operation(sameVolume: Bool, optionDown: Bool) -> TransferOperation {
        sameVolume && !optionDown ? .move : .copy
    }

    public static func canTransfer(_ source: URL, into folder: URL) -> Bool {
        let sourcePath = source.standardizedFileURL.path
        let folderPath = folder.standardizedFileURL.path
        return folderPath != sourcePath && !folderPath.hasPrefix(sourcePath == "/" ? "/" : sourcePath + "/")
    }

    public static func isAlreadyIn(_ source: URL, folder: URL) -> Bool {
        source.deletingLastPathComponent().standardizedFileURL.path == folder.standardizedFileURL.path
    }
}
