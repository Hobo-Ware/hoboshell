import AppKit
import HoboshellCore

final class SwitcherController {
    private let panel = WindowSwitcherPanel()
    private let tap = SwitcherEventTap()
    private let engine: ShellEngine
    private var holder: SwitcherModifier?
    private var settingObserver: NSObjectProtocol?

    init(engine: ShellEngine) {
        self.engine = engine
    }

    deinit {
        if let settingObserver {
            NotificationCenter.default.removeObserver(settingObserver)
        }
    }

    func start() {
        panel.onCommit = { WindowCatalog.shared.focus($0) }
        panel.onQuit = { $0.app.terminate() }
        panel.onClose = { WindowCatalog.shared.close($0) }
        panel.onEnd = { [weak self] in
            self?.holder = nil
        }
        tap.onEvent = { [weak self] event in
            self?.handle(event) ?? false
        }
        engine.store.subscribe { [weak self] update in
            guard update.change.touchesWindowsOrApps || update.change.recencyChanged || update.change.desktopChanged else { return }
            self?.stateDidChange()
        }
        settingObserver = NotificationCenter.default.addObserver(
            forName: SwitcherSettings.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.applySetting()
        }
        applySetting()
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
        panel.begin(windows: currentWindows(), holding: nil, forward: true, on: screen)
    }

    private func stateDidChange() {
        guard panel.isShowing else { return }
        panel.update(windows: currentWindows())
    }

    private func currentWindows() -> [ShellWindow] {
        let running = Dictionary(engine.tracker.shellApps.map { ($0.processIdentifier, $0) }, uniquingKeysWith: { first, _ in first })
        return SwitcherModel.entries(engine.store.state).compactMap { entry in
            running[entry.pid].map {
                ShellWindow(id: entry.windowID, app: $0, title: entry.title, isMinimized: entry.isMinimized, isFocused: false)
            }
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
        guard holder != nil || engine.isTrusted else { return false }
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
        guard engine.isTrusted else {
            holder = nil
            Accessibility.requestTrust()
            return
        }
        guard let screen = NSScreen.main else {
            holder = nil
            return
        }
        holder = holding
        panel.begin(windows: currentWindows(), holding: holding, forward: forward, on: screen)
    }
}
