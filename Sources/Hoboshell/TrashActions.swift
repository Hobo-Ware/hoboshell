import AppKit
import HoboshellCore

enum TrashActions {
    static func droppedURLs(in info: NSDraggingInfo) -> [URL] {
        ExplorerClipboard.fileURLs(from: info.draggingPasteboard).filter {
            ExplorerDropPolicy.canTrash($0, trashFolder: TrashMonitor.folder)
        }
    }

    static func open() {
        ExplorerWindow.open(at: TrashMonitor.folder)
    }

    static func trash(_ urls: [URL], completion: @escaping ([String]) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let failures = ExplorerFileOperations.trash(urls)
            DispatchQueue.main.async {
                completion(failures)
            }
        }
    }

    static func showFailures(_ failures: [String]) {
        guard let first = failures.first else { return }
        let more = failures.count == 1 ? "" : "\n\(failures.count - 1) more failed."
        DSDialog.showError(title: "Could not move to the Trash", message: first + more)
    }
}
