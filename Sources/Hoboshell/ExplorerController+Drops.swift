import AppKit
import HoboshellCore

extension ExplorerController {
    func itemsDropOperation(_ urls: [URL], onto index: Int?, option: Bool, allowed: NSDragOperation) -> NSDragOperation {
        let destination = dropDestination(index)
        switch transferOperation(for: urls, into: destination, option: option, allowed: allowed) {
        case .move: return .move
        case .copy: return .copy
        case nil: return []
        }
    }

    func itemsAcceptDrop(_ urls: [URL], onto index: Int?, option: Bool, allowed: NSDragOperation) -> Bool {
        let destination = dropDestination(index)
        guard let operation = transferOperation(for: urls, into: destination, option: option, allowed: allowed) else { return false }
        let result = ExplorerFileOperations.transfer(urls, into: destination, operation: operation)
        finish(result, into: destination)
        return !result.created.isEmpty || result.failures.isEmpty
    }

    private func dropDestination(_ index: Int?) -> URL {
        guard let index, visibleEntries.indices.contains(index) else { return history.current }
        return visibleEntries[index].url
    }

    private func transferOperation(for urls: [URL], into destination: URL, option: Bool, allowed: NSDragOperation) -> TransferOperation? {
        let transferable = urls.filter { ExplorerDropPolicy.canTransfer($0, into: destination) }
        guard !transferable.isEmpty, FileManager.default.isWritableFile(atPath: destination.path) else { return nil }
        let sameVolume = transferable.allSatisfy { Self.isOnSameVolume($0, as: destination) }
        var operation = ExplorerDropPolicy.operation(sameVolume: sameVolume, optionDown: option)
        if operation == .move, !allowed.contains(.move) {
            operation = .copy
        }
        if operation == .copy, !allowed.contains(.copy), !allowed.contains(.generic) {
            return nil
        }
        if operation == .move, transferable.allSatisfy({ ExplorerDropPolicy.isAlreadyIn($0, folder: destination) }) {
            return nil
        }
        return operation
    }

    private static func isOnSameVolume(_ first: URL, as second: URL) -> Bool {
        let keys: Set<URLResourceKey> = [.volumeIdentifierKey]
        guard let firstID = (try? first.resourceValues(forKeys: keys))?.volumeIdentifier,
              let secondID = (try? second.resourceValues(forKeys: keys))?.volumeIdentifier else { return false }
        return firstID.isEqual(secondID)
    }
}
