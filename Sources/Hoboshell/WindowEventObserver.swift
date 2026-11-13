import AppKit
import ApplicationServices
import HoboshellCore

final class WindowEventObserver {
    private static let launchRetryDelays: [TimeInterval] = [0.1, 0.3, 1]
    private static let desktopRecheckDelay: TimeInterval = 0.25

    var onGeometryChange: ((AXUIElement) -> Void)?

    private let worker = AXWorker.shared
    private let registry: WindowRegistry
    private var watchers: [pid_t: AppWatcher] = [:]

    init(registry: WindowRegistry) {
        self.registry = registry
    }

    func appLaunched(pid: pid_t, name: String) {
        worker.async { [weak self] in
            self?.startWatching(pid: pid, name: name)
        }
    }

    func appTerminated(pid: pid_t) {
        worker.async { [weak self] in
            self?.watchers.removeValue(forKey: pid)?.stop()
        }
    }

    func sync(apps: [(pid: pid_t, name: String)], snapshot reason: ShellEvent.SnapshotReason) {
        worker.async { [weak self] in
            guard let self else { return }
            let running = Set(apps.map(\.pid))
            for pid in watchers.keys where !running.contains(pid) {
                watchers.removeValue(forKey: pid)?.stop()
            }
            var started = Set<pid_t>()
            for app in apps where watchers[app.pid] == nil {
                startWatching(pid: app.pid, name: app.name)
                started.insert(app.pid)
            }
            snapshotAll(reason, skipping: started)
        }
    }

    func desktopChanged() {
        worker.async { [weak self] in
            self?.snapshotAll(.desktopChange)
        }
        worker.after(Self.desktopRecheckDelay) { [weak self] in
            self?.snapshotAll(.desktopChange)
        }
    }

    func stopAll() {
        worker.async { [weak self] in
            guard let self else { return }
            watchers.values.forEach { $0.stop() }
            watchers = [:]
        }
    }

    private func startWatching(pid: pid_t, name: String) {
        guard watchers[pid] == nil else { return }
        let watcher = AppWatcher(pid: pid, name: name, registry: registry) { kind, observedAt in
            ShellStore.post(kind, observedAt: observedAt)
        }
        watcher.onGeometryChange = { [weak self] element in
            DispatchQueue.main.async {
                self?.onGeometryChange?(element)
            }
        }
        guard watcher.start() else { return }
        watchers[pid] = watcher
        snapshotUntilWindowsAppear(pid: pid, delays: Self.launchRetryDelays[...])
    }

    private func snapshotUntilWindowsAppear(pid: pid_t, delays: ArraySlice<TimeInterval>) {
        guard let watcher = watchers[pid] else { return }
        let windows = watcher.snapshot()
        if let windows {
            post(windows, pid: pid, reason: .launch)
        }
        guard windows?.isEmpty ?? true, let delay = delays.first else { return }
        worker.after(delay) { [weak self] in
            self?.snapshotUntilWindowsAppear(pid: pid, delays: delays.dropFirst())
        }
    }

    private func snapshotAll(_ reason: ShellEvent.SnapshotReason, skipping skipped: Set<pid_t> = []) {
        for (pid, watcher) in watchers where !skipped.contains(pid) {
            if let windows = watcher.snapshot() {
                post(windows, pid: pid, reason: reason)
            }
        }
    }

    private func post(_ windows: [WindowState], pid: pid_t, reason: ShellEvent.SnapshotReason) {
        ShellStore.post(.appSnapshot(pid: pid, windows: windows, reason: reason))
    }
}
