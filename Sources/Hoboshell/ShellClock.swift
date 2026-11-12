import Dispatch

enum ShellClock {
    static func now() -> UInt64 {
        DispatchTime.now().uptimeNanoseconds
    }

    static func milliseconds(since start: UInt64) -> Double {
        Double(now() &- start) / 1_000_000
    }
}
