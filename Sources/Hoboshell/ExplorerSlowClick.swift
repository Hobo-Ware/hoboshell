import AppKit

final class ExplorerSlowClick {
    private static let extraDelay: TimeInterval = 0.15

    private var timer: Timer?

    func arm(_ action: @escaping () -> Void) {
        cancel()
        timer = Timer.scheduledTimer(withTimeInterval: NSEvent.doubleClickInterval + Self.extraDelay, repeats: false) { [weak self] _ in
            self?.timer = nil
            action()
        }
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
    }

    deinit {
        timer?.invalidate()
    }
}
