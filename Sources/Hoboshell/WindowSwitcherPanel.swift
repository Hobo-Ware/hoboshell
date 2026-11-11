import AppKit
import HoboshellCore

final class WindowSwitcherPanel: NSPanel {
    private static let panelWidth: CGFloat = 460
    private static let rowHeight: CGFloat = 36
    private static let padding: CGFloat = 10
    private static let maxRows = 12

    private let rows = NSStackView()
    private var windows: [ShellWindow] = []
    private var selected: Int?
    private var modifierMonitors: [Any] = []

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.panelWidth, height: Self.rowHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        appearance = NSAppearance(named: .darkAqua)
        hidesOnDeactivate = false
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true

        let background = NSVisualEffectView()
        background.material = .hudWindow
        background.blendingMode = .behindWindow
        background.state = .active
        background.wantsLayer = true
        background.layer?.cornerRadius = 10
        background.layer?.masksToBounds = true
        contentView = background

        rows.orientation = .vertical
        rows.alignment = .leading
        rows.spacing = 0
        rows.edgeInsets = NSEdgeInsets(top: Self.padding, left: Self.padding, bottom: Self.padding, right: Self.padding)
        rows.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(rows)
        NSLayoutConstraint.activate([
            rows.leadingAnchor.constraint(equalTo: background.leadingAnchor),
            rows.trailingAnchor.constraint(equalTo: background.trailingAnchor),
            rows.topAnchor.constraint(equalTo: background.topAnchor),
            rows.bottomAnchor.constraint(equalTo: background.bottomAnchor),
        ])
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
            let icon = NSImageView(image: window.app.icon ?? NSImage())
            icon.translatesAutoresizingMaskIntoConstraints = false
            let appName = window.app.localizedName ?? ""
            let text = window.title == appName ? appName : "\(appName) - \(window.title)"
            let label = NSTextField(labelWithString: text)
            label.lineBreakMode = .byTruncatingTail
            label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
            let row = NSStackView(views: [icon, label])
            row.orientation = .horizontal
            row.spacing = 10
            row.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
            row.wantsLayer = true
            row.layer?.cornerRadius = 6
            NSLayoutConstraint.activate([
                icon.widthAnchor.constraint(equalToConstant: 24),
                icon.heightAnchor.constraint(equalToConstant: 24),
                row.heightAnchor.constraint(equalToConstant: Self.rowHeight),
                row.widthAnchor.constraint(equalToConstant: Self.panelWidth - Self.padding * 2),
            ])
            rows.addArrangedSubview(row)
        }
        highlightSelection()
    }

    private func highlightSelection() {
        for (index, row) in rows.arrangedSubviews.enumerated() {
            row.layer?.backgroundColor = index == selected ? NSColor.white.withAlphaComponent(0.22).cgColor : nil
        }
    }
}
