public struct ShellEvent: Equatable {
    public enum SnapshotReason: Equatable {
        case launch
        case desktopChange
        case trusted
        case sweep
    }

    public enum Kind: Equatable {
        case appLaunched(ShellApp)
        case appTerminated(pid: Int32)
        case appActivated(pid: Int32)
        case appHidden(pid: Int32)
        case appUnhidden(pid: Int32)
        case appsRead([ShellApp])
        case windowCreated(WindowState)
        case windowDestroyed(id: Int)
        case windowTitleChanged(id: Int, title: String)
        case windowMinimized(id: Int)
        case windowRestored(id: Int)
        case windowFocused(id: Int)
        case appSnapshot(pid: Int32, windows: [WindowState], reason: SnapshotReason)
        case desktopChanged
        case badgesRead([String: String])
        case pinsChanged(TaskbarPins)
    }

    public let kind: Kind
    public let observedAt: UInt64

    public init(_ kind: Kind, observedAt: UInt64 = 0) {
        self.kind = kind
        self.observedAt = observedAt
    }
}
