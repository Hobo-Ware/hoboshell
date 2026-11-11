import AppKit
import HoboshellCore

final class WindowSwitcherPanel: NSPanel {
    private static let panelWidth: CGFloat = 460
    private static let rowHeight = DSControlHeight.taskbar.value
    private static let padding = DSSpacing.m
    private static let maxRows = 12

    private let rows = NSStackView()
    private var windows: [ShellWindow] = []
    private var selected: Int?
    private var modifierMonitors: [Any] = []

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.rowHeight),
            styleMask: DSPanelStyle.styleMask,
            backing: .buffered,
            defer: false
        )
        let background = DSPanelStyle.apply(to: self, kind: .flyout, level: .popUpMenu)

        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = 0
        rows.edgeInsets = NSEdgeInsets(top: Self.padding, left: Self.padding, bottom: Self.padding, right: Self.padding)
        DSPanelStyle.pin(rows, to: background)
    }

    override var canBecomeKey: Bool { false }

    func begin(with candidates: [ShellWindow], on screen: NSScreen) {
        windows = Array(candidates.prefix(Self.maxRows))
        selected = SwitcherSelection.initial(count: windows.count)
        guard selected != nil else { return }
        guard NSEvent.modifierFlags.contains(.option) else {
            commit()
            return
        }
        rebuildRows()
        let height = CGFloat(windows.count) * Self.rowHeight + Self.padding * 2
        setFrame(
            NSRect(
                x: screen.frame.midX - Self.panelWidth / 2,
                y: screen.frame.midY - height / 2,
                width: Self.panelWidth,
                height: height
            ),
            display: true
        )
        orderFrontRegardless()
        watchForOptionRelease()
    }

    func advance() {
        guard let current = selected else { return }
        selected = SwitcherSelection.next(after: current, count: windows.count)
        highlightSelection()
    }

    private func commit() {
        modifierMonitors.forEach(NSEvent.removeMonitor)
        modifierMonitors = []
        orderOut(nil)
        if let selected, windows.indices.contains(selected) {
            WindowCatalog.focus(windows[selected])
        }
        windows = []
        selected = nil
    }

    private func watchForOptionRelease() {
        let commitWhenReleased: (NSEvent) -> Void = { [weak self] event in
            if !event.modifierFlags.contains(.option) {
                self?.commit()
            }
        }
        if let global = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged, handler: commitWhenReleased) {
            modifierMonitors.append(global)
        }
        let local = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { event in
            commitWhenReleased(event)
            return event
        }
        if let local {
            modifierMonitors.append(local)
        }
    }

    private func rebuildRows() {
        rows.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for window in windows {
            let appName = window.app.localizedName ?? ""
            let text = window.title == appName ? appName : "\(appName) - \(window.title)"
            let row = DSListRow(title: text, image: window.app.icon ?? NSImage(), height: .taskbar)
            row.makeStatic()
            row.widthAnchor.constraint(equalToConstant: Self.panelWidth - Self.padding * 2).isActive = true
            rows.addArrangedSubview(row)
        }
        highlightSelection()
    }

    private func highlightSelection() {
        for case let row as DSListRow in rows.arrangedSubviews {
            row.isSelected = rows.arrangedSubviews.firstIndex(of: row) == selected
        }
    }
}
