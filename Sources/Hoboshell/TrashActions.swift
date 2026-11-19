import AppKit
import HoboshellCore

enum TrashActions {
    static func droppedURLs(in info: NSDraggingInfo) -> [URL] {
        ExplorerClipboard.fileURLs(from: info.draggingPasteboard).filter {
            ExplorerDropPolicy.canTrash($0, trashFolder: TrashMonitor.folder)
        }
    }

    static func open() {
        guard TrashMonitor.shared.contents.canBrowse else {
            NSWorkspace.shared.open(TrashMonitor.folder)
            return
        }
        ExplorerWindow.open(at: TrashMonitor.folder)
    }

    static func needsFinder(for url: URL) -> Bool {
        url.standardizedFileURL.path == TrashMonitor.folder.standardizedFileURL.path
            && !TrashMonitor.shared.contents.canBrowse
    }

    static func trash(_ urls: [URL], completion: @escaping ([String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let failures = ExplorerFileOperations.trash(urls)
            DispatchQueue.main.async {
                completion(failures)
            }
        }
    }

    static func confirmAndEmpty() {
        let contents = TrashMonitor.shared.contents
        let what = contents.countText.map { "The \($0) in the Trash" } ?? "Everything in the Trash"
        guard DSDialog.confirm(
            title: "Empty the Trash?",
            message: "\(what) will be deleted for good. You can't undo this.",
            confirmTitle: "Empty Trash",
            isDestructive: true
        ) else { return }
        DispatchQueue.global(qos: .userInitiated).async {
            let failure = askFinderToEmpty()
            DispatchQueue.main.async {
                TrashMonitor.shared.refreshSoon()
                guard let failure else { return }
                DSDialog.showError(title: "Could not empty the Trash", message: failure)
            }
        }
    }

    private static func askFinderToEmpty() -> String? {
        let event = NSAppleEventDescriptor(
            eventClass: finderSuite,
            eventID: emptyEvent,
            targetDescriptor: NSAppleEventDescriptor(bundleIdentifier: finderBundleID),
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        do {
            _ = try event.sendEvent(options: [.waitForReply], timeout: emptyTimeout)
            return nil
        } catch {
            let code = (error as NSError).code
            if code == Int(errAEEventNotPermitted) {
                return "Hoboshell is not allowed to control Finder. Turn it on in System Settings > Privacy & Security > Automation."
            }
            return error.localizedDescription
        }
    }

    private static let finderBundleID = "com.apple.finder"
    private static let finderSuite: AEEventClass = 0x666E_6472
    private static let emptyEvent: AEEventID = 0x656D_7074
    private static let emptyTimeout: TimeInterval = 120

    static func showFailures(_ failures: [String]) {
        guard let first = failures.first else { return }
        let more = failures.count == 1 ? "" : "\n\(failures.count - 1) more failed."
        DSDialog.showError(title: "Could not move to the Trash", message: first + more)
    }
}
