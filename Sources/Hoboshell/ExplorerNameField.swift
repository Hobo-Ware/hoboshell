import AppKit

final class ExplorerNameField: NSTextField, NSTextFieldDelegate {
    var onCommit: ((String) -> Void)?
    var onCancel: (() -> Void)?

    private var cancelled = false
    private var originalName = ""
    private var isRenaming = false

    func beginRenaming(stemLength: Int) -> Bool {
        originalName = stringValue
        cancelled = false
        isRenaming = true
        delegate = self
        isEditable = true
        isSelectable = true
        drawsBackground = true
        backgroundColor = DSColor.field
        guard window?.makeFirstResponder(self) == true, let editor = currentEditor() else {
            isRenaming = false
            isEditable = false
            isSelectable = false
            drawsBackground = false
            return false
        }
        editor.selectedRange = NSRange(location: 0, length: stemLength)
        return true
    }

    override func textDidEndEditing(_ notification: Notification) {
        super.textDidEndEditing(notification)
        guard isRenaming else { return }
        isRenaming = false
        isEditable = false
        isSelectable = false
        drawsBackground = false
        let committed = stringValue
        let wasCancelled = cancelled
        if wasCancelled {
            stringValue = originalName
        }
        DispatchQueue.main.async { [weak self] in
            if wasCancelled {
                self?.onCancel?()
            } else {
                self?.onCommit?(committed)
            }
        }
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard commandSelector == #selector(NSResponder.cancelOperation(_:)) else { return false }
        cancelled = true
        window?.makeFirstResponder(nil)
        return true
    }
}
