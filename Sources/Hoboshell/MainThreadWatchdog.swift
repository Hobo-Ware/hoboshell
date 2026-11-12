import Foundation
import os

final class MainThreadWatchdog {
    private static let pingInterval: TimeInterval = 0.05
    private static let stallThreshold: TimeInterval = 0.1

    private let queue = DispatchQueue(label: "dev.hoboware.hoboshell.watchdog", qos: .utility)
    private var timer: DispatchSourceTimer?
    private var pending: UInt64?

    func start() {
        guard timer == nil else { return }
        let source = DispatchSource.makeTimerSource(queue: queue)
        source.schedule(deadline: .now() + Self.pingInterval, repeating: Self.pingInterval, leeway: .milliseconds(10))
        source.setEventHandler { [weak self] in
            self?.ping()
        }
        source.resume()
        timer = source
    }

    private func ping() {
        let now = ShellClock.now()
        if let since = pending {
            report(stalledSince: since, now: now)
            return
        }
        pending = now
        DispatchQueue.main.async { [weak self] in
            self?.queue.async {
                self?.pending = nil
            }
        }
    }

    private func report(stalledSince since: UInt64, now: UInt64) {
        let milliseconds = Double(now &- since) / 1_000_000
        guard milliseconds > Self.stallThreshold * 1_000 else { return }
        PerfLog.stalls.notice("main thread stalled for \(milliseconds, format: .fixed(precision: 0)) ms")
    }
}
