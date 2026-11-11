import AppKit

final class ExplorerClipboard {
    static let shared = ExplorerClipboard()

    private let pasteboard = NSPasteboard.general
    private var cutChangeCount: Int?

    var hasFiles: Bool {
        pasteboard.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
    }

    var isCutPending: Bool {
        cutChangeCount == pasteboard.changeCount
    }

    static func fileURLs(from pasteboard: NSPasteboard) -> [URL] {
        let objects = pasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true])
        return (objects as? [URL]) ?? []
    }

    func read() -> (urls: [URL], isCut: Bool) {
        (Self.fileURLs(from: pasteboard), isCutPending)
    }

    func write(_ urls: [URL], cut: Bool) {
        pasteboard.clearContents()
        pasteboard.writeObjects(urls.map { $0 as NSURL })
        cutChangeCount = cut ? pasteboard.changeCount : nil
    }

    func finishCut(movedTo urls: [URL]) {
        write(urls, cut: false)
    }

    func writeText(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        cutChangeCount = nil
    }
}
