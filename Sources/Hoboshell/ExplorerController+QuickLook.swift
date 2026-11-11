import AppKit
import Quartz

extension ExplorerController: QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    func quickLook() {
        guard let panel = QLPreviewPanel.shared() else { return }
        if panel.isVisible {
            panel.orderOut(nil)
            return
        }
        guard !selectedEntries.isEmpty else { return }
        panel.makeKeyAndOrderFront(nil)
    }

    func reloadQuickLook() {
        guard QLPreviewPanel.sharedPreviewPanelExists(), let panel = QLPreviewPanel.shared(),
              panel.isVisible, (panel.dataSource as AnyObject?) === self else { return }
        panel.reloadData()
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        selectedEntries.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        let entries = selectedEntries
        return entries.indices.contains(index) ? entries[index].url as NSURL : nil
    }
}
