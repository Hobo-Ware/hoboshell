import AppKit

final class DSHoverSync {
    private var observer: NSObjectProtocol?

    deinit {
        stop()
    }

    static func isPointerInside(_ view: NSView) -> Bool {
        guard let window = view.window else { return false }
        return view.visibleRect.contains(view.convert(window.mouseLocationOutsideOfEventStream, from: nil))
    }

    func follow(scrollingOf view: NSView, onScroll: @escaping () -> Void) {
        stop()
        guard let clipView = view.enclosingScrollView?.contentView else { return }
        clipView.postsBoundsChangedNotifications = true
        observer = NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: clipView,
            queue: .main
        ) { _ in
            onScroll()
        }
    }

    private func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
    }
}
