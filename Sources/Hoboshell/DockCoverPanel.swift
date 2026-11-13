import AppKit

final class DockCoverPanel: NSPanel {
    init(covering strip: NSRect) {
        super.init(contentRect: strip, styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        // The overview hides ordinary panels, the taskbar included, and would leave the real Dock showing.
        // A stationary window stays put there, so this plain strip keeps the Dock covered.
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.dockWindow)) + 1)
        isOpaque = true
        backgroundColor = DSColor.surface
        hasShadow = false
        ignoresMouseEvents = true
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
