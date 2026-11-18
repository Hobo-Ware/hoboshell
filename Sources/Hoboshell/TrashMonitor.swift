import AppKit
import HoboshellCore

final class TrashMonitor {
    static let shared = TrashMonitor()
    static let didChange = Notification.Name("HoboshellTrashDidChange")
    static let folder: URL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first
        ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")

    private(set) var contents = TrashContents.unreadable

    private let queue = DispatchQueue(label: "hoboshell.trash-monitor", qos: .utility)
    private var source: DispatchSourceFileSystemObject?

    private init() {
        queue.async { [weak self] in
            self?.watch()
            self?.refresh()
        }
    }

    private func watch() {
        let descriptor = open(Self.folder.path, O_EVTONLY)
        guard descriptor >= 0 else { return }
        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .delete, .rename, .extend, .link],
            queue: queue
        )
        source.setEventHandler { [weak self] in
            self?.refresh()
        }
        source.setCancelHandler {
            close(descriptor)
        }
        source.resume()
        self.source = source
    }

    private func refresh() {
        let names = try? FileManager.default.contentsOfDirectory(atPath: Self.folder.path)
        let next = TrashContents(entryNames: names)
        DispatchQueue.main.async { [weak self] in
            guard let self, self.contents != next else { return }
            self.contents = next
            NotificationCenter.default.post(name: Self.didChange, object: nil)
        }
    }
}
