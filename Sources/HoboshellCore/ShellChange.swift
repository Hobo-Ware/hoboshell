public struct ShellChange: Equatable {
    public var appsAdded: [Int32] = []
    public var appsRemoved: [Int32] = []
    public var appsChanged: [Int32] = []
    public var windowsAdded: [Int] = []
    public var windowsRemoved: [Int] = []
    public var windowsChanged: [Int] = []
    public var badgesChanged = false
    public var pinsChanged = false
    public var recencyChanged = false
    public var desktopChanged = false
    public var drift: [String] = []

    public init() {}

    public var isEmpty: Bool {
        self == ShellChange()
    }

    public var touchesWindowsOrApps: Bool {
        !(appsAdded.isEmpty && appsRemoved.isEmpty && appsChanged.isEmpty
            && windowsAdded.isEmpty && windowsRemoved.isEmpty && windowsChanged.isEmpty)
    }

    mutating func added(app pid: Int32) { Self.note(pid, in: &appsAdded) }
    mutating func removed(app pid: Int32) { Self.note(pid, in: &appsRemoved) }
    mutating func changed(app pid: Int32) { Self.note(pid, in: &appsChanged) }
    mutating func added(window id: Int) { Self.note(id, in: &windowsAdded) }
    mutating func removed(window id: Int) { Self.note(id, in: &windowsRemoved) }
    mutating func changed(window id: Int) { Self.note(id, in: &windowsChanged) }

    private static func note<Value: Equatable>(_ value: Value, in list: inout [Value]) {
        if !list.contains(value) {
            list.append(value)
        }
    }
}
