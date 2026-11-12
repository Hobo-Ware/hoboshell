public struct ShellApp: Equatable {
    public enum Policy: Equatable {
        case regular
        case accessory
        case prohibited
    }

    public let pid: Int32
    public var bundleID: String?
    public var name: String
    public var policy: Policy
    public var isHidden: Bool
    public var isActive: Bool
    public internal(set) var hasReadWindows = false

    public init(
        pid: Int32,
        bundleID: String?,
        name: String,
        policy: Policy = .regular,
        isHidden: Bool = false,
        isActive: Bool = false
    ) {
        self.pid = pid
        self.bundleID = bundleID
        self.name = name
        self.policy = policy
        self.isHidden = isHidden
        self.isActive = isActive
    }

    public var appID: String {
        TaskbarAppID.make(bundleIdentifier: bundleID, pid: pid)
    }
}
