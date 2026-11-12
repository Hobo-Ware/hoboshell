import AppKit
import HoboshellCore

extension ShellApp {
    init(running app: NSRunningApplication) {
        let policy: Policy
        switch app.activationPolicy {
        case .regular: policy = .regular
        case .accessory: policy = .accessory
        default: policy = .prohibited
        }
        self.init(
            pid: app.processIdentifier,
            bundleID: app.bundleIdentifier,
            name: app.localizedName ?? "",
            bundlePath: app.bundleURL?.path,
            policy: policy,
            isHidden: app.isHidden,
            isActive: app.isActive
        )
    }
}
