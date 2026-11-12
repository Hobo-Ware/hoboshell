public struct OtherDesktopApps {
    private var lastWithWindows: Set<Int32> = []
    private var elsewhere: Set<Int32> = []

    public init() {}

    public mutating func desktopChanged() {
        elsewhere.formUnion(lastWithWindows)
    }

    public mutating func hasWindowsElsewhere(_ pid: Int32, appsWithWindowsHere: Set<Int32>) -> Bool {
        elsewhere.subtract(appsWithWindowsHere)
        lastWithWindows = appsWithWindowsHere
        return elsewhere.contains(pid)
    }
}
