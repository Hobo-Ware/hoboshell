import AppKit
import HoboshellCore

final class SideDockPanel: NSPanel {
    var onFiles: (() -> Void)?
    var onShowApps: (() -> Void)?

    private let itemStack = NSStackView()
    private lazy var buttons = KeyedStack<DSButton>(stack: itemStack)
    private var state = ShellState()
    private var isTrusted = true
    private var specs: [String: TaskbarButtonSpec] = [:]
    private var hasPresented = false
    private var iconObserver: NSObjectProtocol?

    init(frame: NSRect, contextMenu: NSMenu, kind: DSPanelStyle.Kind = .bar) {
        super.init(contentRect: frame, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: false)
        let background = DSPanelStyle.apply(to: self, kind: kind)

        let filesButton = DSButton(image: HoboIcon.files.image(side: DSIconSize.startLogo), height: .taskbar, tip: "Files")
        filesButton.onPress = { [weak self] in
            self?.onFiles?()
        }
        let appsButton = DSButton(symbol: "square.grid.3x3.fill", tip: "Show apps", height: .taskbar)
        appsButton.onPress = { [weak self] in
            self?.onShowApps?()
        }

        itemStack.orientation = .vertical
        itemStack.spacing = DSSpacing.xs

        let root = NSStackView()
        root.orientation = .vertical
        root.alignment = .centerX
        root.spacing = DSSpacing.xs
        root.edgeInsets = NSEdgeInsets(top: DSSpacing.s, left: 0, bottom: DSSpacing.s, right: 0)
        root.addView(filesButton, in: .top)
        root.addView(itemStack, in: .top)
        root.addView(appsButton, in: .bottom)
        DSPanelStyle.pin(root, to: background)
        background.menu = contextMenu
        iconObserver = NotificationCenter.default.addObserver(
            forName: AppIcons.didLoad, object: nil, queue: .main
        ) { [weak self] _ in
            self?.present()
        }
    }

    deinit {
        if let iconObserver {
            NotificationCenter.default.removeObserver(iconObserver)
        }
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func update(state: ShellState, isTrusted: Bool) {
        self.state = state
        self.isTrusted = isTrusted
        present()
    }

    private func present() {
        let all = TaskbarModel.make(
            state,
            grouping: .never,
            availableWidth: .greatestFiniteMagnitude,
            spacing: DSSpacing.xs,
            listsAppsWithoutWindows: !isTrusted
        )
        let shown = all.filter { !$0.windowIDs.isEmpty || (!isTrusted && $0.isRunning) }
        specs = Dictionary(shown.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        buttons.apply(
            keys: shown.map(\.id),
            animated: hasPresented,
            make: { [weak self] id in
                let button = DSButton(image: nil, height: .taskbar, tip: "")
                button.onPress = {
                    guard let self, let spec = self.specs[id] else { return }
                    TaskbarActions.click(spec, in: self.state)
                }
                return button
            },
            update: { [weak self] button, id in
                guard let self, let spec = self.specs[id] else { return }
                let icon = AppIcons.shared.image(forPath: spec.pid.flatMap { self.state.app(pid: $0)?.bundlePath })
                if button.image !== icon {
                    button.image = icon
                }
                if button.toolTip != spec.title {
                    button.toolTip = spec.title
                    button.setAccessibilityLabel(spec.title)
                }
                if button.isSelected != spec.isActive {
                    button.isSelected = spec.isActive
                }
            }
        )
        hasPresented = true
    }
}
