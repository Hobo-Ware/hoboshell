public struct WindowState: Equatable {
    public let id: Int
    public let pid: Int32
    public var title: String
    public var isMinimized: Bool
    public var isFocused: Bool
    public var isOnThisDesktop: Bool

    public init(
        id: Int,
        pid: Int32,
        title: String,
        isMinimized: Bool = false,
        isFocused: Bool = false,
        isOnThisDesktop: Bool = true
    ) {
        self.id = id
        self.pid = pid
        self.title = title
        self.isMinimized = isMinimized
        self.isFocused = isFocused
        self.isOnThisDesktop = isOnThisDesktop
    }
}
