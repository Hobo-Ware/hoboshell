import Foundation
import IOKit.ps

final class TrayPowerWatcher {
    private let onChange: () -> Void
    private var source: CFRunLoopSource?

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
        let context = Unmanaged.passUnretained(self).toOpaque()
        source = IOPSNotificationCreateRunLoopSource({ context in
            guard let context else { return }
            Unmanaged<TrayPowerWatcher>.fromOpaque(context).takeUnretainedValue().onChange()
        }, context)?.takeRetainedValue()
        if let source {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }

    deinit {
        if let source {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }
}
