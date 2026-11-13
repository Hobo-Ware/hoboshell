import AppKit
import ApplicationServices

struct ShellWindow {
    let id: Int
    let app: NSRunningApplication
    let title: String
    let isMinimized: Bool
    let isFocused: Bool
}

final class WindowCatalog {
    static let shared = WindowCatalog()
    static let messagingTimeout: Float = 0.25

    let registry = WindowRegistry()

    func focus(_ window: ShellWindow) {
        let app = window.app
        perform(on: window) { element in
            _ = AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            _ = AXUIElementPerformAction(element, kAXRaiseAction as CFString)
            _ = AXUIElementSetAttributeValue(element, kAXMainAttribute as CFString, kCFBooleanTrue)
        }
        app.unhide()
        app.activate()
    }

    func minimize(_ window: ShellWindow) {
        perform(on: window) { element in
            _ = AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString, kCFBooleanTrue)
        }
    }

    func close(_ window: ShellWindow) {
        perform(on: window) { element in
            guard let button = Self.attribute(kAXCloseButtonAttribute, of: element),
                  CFGetTypeID(button) == AXUIElementGetTypeID() else { return }
            let pressable = button as! AXUIElement
            Self.timeout(pressable)
            _ = AXUIElementPerformAction(pressable, kAXPressAction as CFString)
        }
    }

    private func perform(on window: ShellWindow, _ action: @escaping (AXUIElement) -> Void) {
        let id = window.id
        let isOwnWindow = window.app.processIdentifier == ProcessInfo.processInfo.processIdentifier
        AXWorker.shared.async { [registry] in
            guard let element = registry.element(of: id) else { return }
            Self.timeout(element)
            // AppKit answers Accessibility calls on our own windows inside this process and only on the main thread.
            if isOwnWindow {
                DispatchQueue.main.async { action(element) }
            } else {
                action(element)
            }
        }
    }

    func frame(of id: Int) async -> CGRect? {
        await withCheckedContinuation { continuation in
            AXWorker.shared.async { [registry] in
                continuation.resume(returning: registry.element(of: id).flatMap(Self.frame(of:)))
            }
        }
    }

    static func timeout(_ element: AXUIElement) {
        AXUIElementSetMessagingTimeout(element, messagingTimeout)
    }

    static func frame(of element: AXUIElement) -> CGRect? {
        guard let position = attribute(kAXPositionAttribute, of: element),
              let size = attribute(kAXSizeAttribute, of: element),
              CFGetTypeID(position) == AXValueGetTypeID(),
              CFGetTypeID(size) == AXValueGetTypeID() else { return nil }
        var origin = CGPoint.zero
        var extent = CGSize.zero
        guard AXValueGetValue(position as! AXValue, .cgPoint, &origin),
              AXValueGetValue(size as! AXValue, .cgSize, &extent) else { return nil }
        return CGRect(origin: origin, size: extent)
    }

    static func attribute(_ name: String, of element: AXUIElement) -> CFTypeRef? {
        timeout(element)
        var value: CFTypeRef?
        return AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success ? value : nil
    }
}
