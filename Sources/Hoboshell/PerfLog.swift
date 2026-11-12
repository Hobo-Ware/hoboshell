import Foundation
import HoboshellCore
import os

enum PerfLog {
    static let isEnabled = CommandLine.arguments.contains("--perf-log")
    static let latency = Logger(subsystem: "dev.hoboware.hoboshell", category: "latency")
    static let stalls = Logger(subsystem: "dev.hoboware.hoboshell", category: "perf")

    static var watchesMainThread: Bool {
        #if DEBUG
        return true
        #else
        return isEnabled
        #endif
    }

    static func shown(_ event: ShellEvent) {
        guard isEnabled, event.observedAt != 0 else { return }
        let label = String(describing: event.kind).prefix { $0 != "(" }
        let milliseconds = ShellClock.milliseconds(since: event.observedAt)
        latency.notice("\(label, privacy: .public) -> shown \(milliseconds, format: .fixed(precision: 1)) ms")
    }
}
