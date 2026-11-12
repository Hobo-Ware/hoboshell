import AppKit
import HoboshellCore

final class SwitcherController {
    private let panel = WindowSwitcherPanel()
    private let tap = SwitcherEventTap()
    private let catalog: WindowCatalog
    private let runningApps: () -> [NSRunningApplication]
    private var recency = WindowRecency()
    private var snapshot: [ShellWindow] = []
    private var holder: SwitcherModifier?
    private var settingObserver: NSObjectProtocol?

    init(catalog: WindowCatalog, runningApps: @escaping () -> [NSRunningApplication]) {
        self.catalog = catalog
        self.runningApps = runningApps
    }

    deinit {
        if let settingObserver {
            NotificationCenter.default.removeObserver(settingObserver)
        }
    }

    func start() {
        panel.onCommit = { [weak self] window in
            self?.recency.activated(window.id)
            WindowCatalog.focus(window)
        }
        panel.onQuit = { $0.app.terminate() }
        panel.onClose = { WindowCatalog.close($0) }
        panel.onEnd = { [weak self] in
            self?.holder = nil
        }
        tap.onEvent = { [weak self] event in
            self?.handle(event) ?? false
        }
        settingObserver = NotificationCenter.default.addObserver(
            forName: SwitcherSettings.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.applySetting()
        }
        applySetting()
    }

    func windowsDidRefresh(_ windows: [ShellWindow]) {
        snapshot = windows
        recency.forget(keeping: Set(windows.map(\.id)))
        if let focused = windows.first(where: \.isFocused) {
            recency.activated(focused.id)
        }
    }

    func openFromHotKey() {
        if panel.isShowing {
            panel.apply(.advance(forward: true))
        } else {
            open(holding: .option, forward: true)
        }
    }

    func showForCapture() {
        guard let screen = NSScreen.main else { return }
        panel.staysOpenForCapture = true
        catalog.load(apps: runningApps()) { [weak self] windows in
            guard let self else { return }
            self.snapshot = windows
            self.panel.begin(windows: self.ordered(windows), holding: nil, forward: true, on: screen)
        }
    }

    private func applySetting() {
        if SwitcherSettings.takesCommandTab {
            tap.install()
        } else {
            tap.remove()
            if holder == .command {
                holder = nil
                panel.finish(commit: false)
            }
        }
    }

    private func handle(_ event: SwitcherKeyEvent) -> Bool {
        guard holder != nil || Accessibility.isTrusted else { return false }
        let decision = SwitcherKeyPolicy.decide(event, holder: holder, takesCommandTab: SwitcherSettings.takesCommandTab)
        if let action = decision.action {
            switch action {
            case .open:
                holder = .command
            case .commit, .cancel:
                holder = nil
            default:
                break
            }
            DispatchQueue.main.async { [weak self] in
                self?.perform(action)
            }
        }
        return decision.swallow
    }

    private func perform(_ action: SwitcherAction) {
        guard case .open(let forward) = action else {
            panel.apply(action)
            return
        }
        open(holding: .command, forward: forward)
    }

    private func open(holding: SwitcherModifier, forward: Bool) {
        guard Accessibility.isTrusted else {
            holder = nil
            Accessibility.requestTrust()
            return
        }
        guard let screen = NSScreen.main else {
            holder = nil
            return
        }
        holder = holding
        let shown = ordered(snapshot)
        guard !shown.isEmpty else {
            catalog.load(apps: runningApps()) { [weak self] windows in
                guard let self else { return }
                self.snapshot = windows
                self.panel.begin(windows: self.ordered(windows), holding: holding, forward: forward, on: screen)
            }
            return
        }
        panel.begin(windows: shown, holding: holding, forward: forward, on: screen)
        catalog.load(apps: runningApps()) { [weak self] windows in
            guard let self else { return }
            self.snapshot = windows
            self.panel.update(windows: self.ordered(windows))
        }
    }

    private func ordered(_ windows: [ShellWindow]) -> [ShellWindow] {
        let byID = Dictionary(windows.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        return recency.ordered(windows.map(\.id)).compactMap { byID[$0] }
    }
}
