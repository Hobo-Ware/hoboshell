import AppKit
import HoboshellCore

final class TrashMonitor {
    static let shared = TrashMonitor()
    static let didChange = Notification.Name("HoboshellTrashDidChange")
    static let folder: URL = FileManager.default.urls(for: .trashDirectory, in: .userDomainMask).first
        ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")

    private(set) var contents = TrashContents.unreadable

    private let queue = DispatchQueue(label: "hoboshell.trash-monitor", qos: .utility)
    private static let privateRecheckInterval: DispatchTimeInterval = .seconds(2)

    private var source: DispatchSourceFileSystemObject?
    private var recheckTimer: DispatchSourceTimer?

    private init() {
        queue.async { [weak self] in
            self?.watch()
            self?.refresh()
        }
    }

    private func watch() {
        let descriptor = open(Self.folder.path, O_EVTONLY)
        guard descriptor >= 0 else {
            recheckPeriodically()
            return
        }
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

    // Without Full Disk Access macOS refuses to watch the Trash folder, so its link count is read on a timer instead.
    private func recheckPeriodically() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + Self.privateRecheckInterval, repeating: Self.privateRecheckInterval)
        timer.setEventHandler { [weak self] in
            self?.refresh()
        }
        timer.resume()
        recheckTimer = timer
    }

    func refreshSoon() {
        queue.async { [weak self] in
            self?.refresh()
        }
    }

    private func refresh() {
        let next = Self.readContents()
        DispatchQueue.main.async { [weak self] in
            guard let self, self.contents != next else { return }
            self.contents = next
            NotificationCenter.default.post(name: Self.didChange, object: nil)
        }
    }

    private static func readContents() -> TrashContents {
        if let names = try? FileManager.default.contentsOfDirectory(atPath: folder.path) {
            return TrashContents(entryNames: names)
        }
        var info = stat()
        guard stat(folder.path, &info) == 0 else { return .unreadable }
        let hidden = TrashContents.knownHiddenNames.filter {
            var entry = stat()
            return lstat(folder.appendingPathComponent($0).path, &entry) == 0
        }
        return TrashContents(folderLinkCount: Int(info.st_nlink), hiddenEntryCount: hidden.count)
    }
}
