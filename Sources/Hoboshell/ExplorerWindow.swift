import AppKit
import HoboshellCore
import Quartz

final class ExplorerWindow: NSWindow, NSWindowDelegate {
    private static let initialSize = NSSize(width: 960, height: 600)
    private static let minimumSize = NSSize(width: 720, height: 440)
    private static let cascadeOffset: CGFloat = 28
    private static var openWindows: [ExplorerWindow] = []

    private let controller: ExplorerController

    static func open(at folder: URL) {
        let window = ExplorerWindow(folder: folder)
        openWindows.append(window)
        if let last = openWindows.dropLast().last {
            window.setFrameOrigin(NSPoint(x: last.frame.minX + cascadeOffset, y: last.frame.minY - cascadeOffset))
        } else {
            window.center()
        }
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
        window.controller.focusItems()
    }

    private init(folder: URL) {
        controller = ExplorerController(folder: folder)
        super.init(
            contentRect: NSRect(origin: .zero, size: Self.initialSize),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        minSize = Self.minimumSize
        appearance = NSAppearance(named: .darkAqua)
        backgroundColor = ExplorerTheme.background
        delegate = self
        contentView = controller.contentView
        controller.window = self
        controller.start()
    }

    func windowWillClose(_ notification: Notification) {
        controller.stop()
        Self.openWindows.removeAll { $0 === self }
    }

    func windowDidBecomeKey(_ notification: Notification) {
        controller.windowBecameKey()
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if firstResponder is NSText {
            return super.performKeyEquivalent(with: event)
        }
        let flags = event.modifierFlags
        let input = ExplorerKeyInput(
            characters: event.charactersIgnoringModifiers ?? "",
            keyCode: event.keyCode,
            command: flags.contains(.command),
            shift: flags.contains(.shift),
            option: flags.contains(.option),
            control: flags.contains(.control)
        )
        guard input.command, let action = ExplorerShortcut.action(for: input) else {
            return super.performKeyEquivalent(with: event)
        }
        controller.perform(action)
        return true
    }

    @objc func copy(_ sender: Any?) {
        controller.copySelection()
    }

    @objc func cut(_ sender: Any?) {
        controller.cutSelection()
    }

    @objc func paste(_ sender: Any?) {
        controller.paste()
    }

    override func selectAll(_ sender: Any?) {
        controller.selectAllItems()
    }

    override func acceptsPreviewPanelControl(_ panel: QLPreviewPanel!) -> Bool {
        true
    }

    override func beginPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = controller
        panel.delegate = controller
    }

    override func endPreviewPanelControl(_ panel: QLPreviewPanel!) {
        panel.dataSource = nil
        panel.delegate = nil
    }
}
