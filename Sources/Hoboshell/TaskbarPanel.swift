import AppKit
import HoboshellCore

final class TaskbarPanel: NSPanel, ShellChrome {
    private static let itemSpacing = DSSpacing.xs
    private static let showDesktopWidth = DSSpacing.s
    private static let widthUsedByFixedControls: CGFloat = 380

    var actions = ShellActions()

    private let itemStack = NSStackView()
    private let previousButton = DSButton(symbol: "chevron.left", tip: "Previous windows", height: .taskbar)
    private let nextButton = DSButton(symbol: "chevron.right", tip: "Next windows", height: .taskbar)
    private lazy var buttons = KeyedStack<TaskbarButton>(stack: itemStack)
    private var state = ShellState()
    private var isTrusted = true
    private var specs: [String: TaskbarButtonSpec] = [:]
    private var grouping = TaskbarPinStore.loadGrouping()
    private var firstIndex = 0
    private var isReordering = false
    private var hasPresented = false
    private var page = TaskbarPage(range: 0..<0, overflows: false, hasPrevious: false, hasNext: false)
    private let previewCard = PreviewCardPanel()
    private var iconObserver: NSObjectProtocol?

    init(layout: ShellLayout, switchTitle: String) {
        super.init(contentRect: layout.bar, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: false)
        let kind: DSPanelStyle.Kind = layout.dockReservation.isOn ? .opaqueBar : .bar
        buildContent(in: DSPanelStyle.apply(to: self, kind: kind), switchTitle: switchTitle)
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

    func show() {
        orderFrontRegardless()
    }

    func dismiss() {
        previewCard.dismiss()
        orderOut(nil)
    }

    func reposition(to layout: ShellLayout) {
        setFrame(layout.bar, display: true)
        present()
    }

    func startMenuOrigin(menuSize: NSSize) -> NSPoint {
        NSPoint(x: frame.minX + DSSpacing.s, y: frame.maxY + DSSpacing.s)
    }

    func update(state: ShellState, isTrusted: Bool) {
        self.state = state
        self.isTrusted = isTrusted
        present()
    }

    private func present() {
        guard !isReordering else { return }
        let available = frame.width - Self.widthUsedByFixedControls
        let all = TaskbarModel.make(
            state,
            grouping: grouping,
            availableWidth: available,
            spacing: Self.itemSpacing,
            listsAppsWithoutWindows: !isTrusted
        )
        let iconOnlyCount = all.filter(\.isIconOnly).count
        let labelledCount = all.count - iconOnlyCount
        let labelledWidth = TaskbarLayout.buttonWidth(
            buttonCount: labelledCount,
            availableWidth: available - CGFloat(iconOnlyCount) * (TaskbarLayout.iconOnlyWidth + Self.itemSpacing),
            spacing: Self.itemSpacing
        )
        let usesLabels = labelledCount > 0 && TaskbarLayout.showsTitle(atWidth: labelledWidth)
        let nextPage = usesLabels
            ? TaskbarPage(range: 0..<all.count, overflows: false, hasPrevious: false, hasNext: false)
            : TaskbarOverflow.page(
                buttonCount: all.count,
                buttonWidth: TaskbarLayout.iconOnlyWidth,
                availableWidth: available,
                spacing: Self.itemSpacing,
                arrowWidth: DSControlHeight.taskbar.value,
                firstIndex: firstIndex
            )
        firstIndex = nextPage.range.lowerBound
        page = nextPage

        let visible = Array(all[nextPage.range])
        let previous = specs
        specs = Dictionary(visible.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let diff = buttons.apply(
            keys: visible.map(\.id),
            animated: hasPresented,
            make: makeButton,
            update: { [weak self] button, id in
                guard let self, let spec = self.specs[id] else { return }
                self.configure(button, with: spec, previous: previous[id], labelled: usesLabels && !spec.isIconOnly, width: labelledWidth)
            }
        )
        hasPresented = true
        if let owner = previewCard.ownerID, diff.removed.contains(owner) {
            previewCard.dismiss()
        }
        previousButton.isHidden = !nextPage.overflows
        nextButton.isHidden = !nextPage.overflows
        previousButton.isEnabled = nextPage.hasPrevious
        nextButton.isEnabled = nextPage.hasNext
    }

    private func makeButton(id: String) -> TaskbarButton {
        let button = TaskbarItemView.make()
        button.onPress = { [weak self, weak button] in
            guard let self, let button else { return }
            self.press(id, button: button)
        }
        button.onReorderingChange = { [weak self] isDragging in
            self?.isReordering = isDragging
            if !isDragging {
                self?.present()
            }
        }
        button.onReorder = { [weak self] center in
            self?.reorder(id, droppedAt: center)
        }
        button.onDragHover = { [weak self] in
            guard let self, let spec = self.specs[id] else { return }
            TaskbarActions.reveal(spec, in: self.state)
        }
        button.onHoverChange = { [weak self, weak button] isInside in
            guard let self, let button, isInside else {
                self?.previewCard.pointerLeft()
                return
            }
            guard let spec = self.specs[id], !spec.windowIDs.isEmpty else { return }
            self.previewCard.pointerEntered(
                owner: id,
                items: { TaskbarActions.items(for: spec, in: self.state) },
                anchor: self.anchor(of: button),
                screen: self.screenFrame
            )
        }
        return button
    }

    private func configure(
        _ button: TaskbarButton,
        with spec: TaskbarButtonSpec,
        previous: TaskbarButtonSpec?,
        labelled: Bool,
        width: CGFloat
    ) {
        let installed = spec.isRunning ? nil : AppIcons.shared.installedApp(spec.appID)
        let name = spec.isRunning ? spec.name : installed?.name ?? ""
        let title = spec.windowIDs.count == 1 ? spec.title : name
        let path = spec.pid.flatMap { state.app(pid: $0)?.bundlePath }
        TaskbarItemView.apply(
            TaskbarItemView.Look(
                title: title,
                tip: title,
                icon: spec.isRunning ? AppIcons.shared.image(forPath: path) : installed?.icon,
                isActive: spec.isActive,
                runState: runState(of: spec),
                width: labelled ? width : TaskbarLayout.iconOnlyWidth,
                isLabelled: labelled,
                count: spec.isGroup ? "\(spec.windowIDs.count)" : nil,
                badge: spec.badge
            ),
            to: button
        )
        button.isReorderable = spec.isPinned
        if spec != previous || button.menu == nil {
            button.menu = TaskbarMenu.make(for: spec, name: name) { [weak self] in
                self?.togglePin(spec.appID)
            }
        }
    }

    private func runState(of spec: TaskbarButtonSpec) -> DSRunMark.State {
        guard spec.isRunning else { return .none }
        if spec.isBackground { return .background }
        return spec.isActive ? .active : .running
    }

    private var screenFrame: NSRect {
        screen?.frame ?? frame
    }

    private func anchor(of button: NSView) -> NSRect {
        convertToScreen(button.convert(button.bounds, to: nil))
    }

    private func press(_ id: String, button: TaskbarButton) {
        guard let spec = specs[id] else { return }
        if spec.isGroup {
            previewCard.showNow(
                owner: id,
                items: TaskbarActions.items(for: spec, in: state),
                anchor: anchor(of: button),
                screen: screenFrame
            )
            return
        }
        previewCard.dismiss()
        TaskbarActions.click(spec, in: state)
    }

    private func commit(_ pins: TaskbarPins) {
        TaskbarPinStore.save(pins)
        ShellStore.shared.apply(ShellEvent(.pinsChanged(pins), observedAt: ShellClock.now()))
    }

    private func togglePin(_ appID: String) {
        let pins = state.pins
        commit(pins.contains(appID) ? pins.removing(appID) : pins.adding(appID))
    }

    private func reorder(_ id: String, droppedAt center: CGFloat) {
        guard let appID = specs[id]?.appID else { return }
        var seen = Set([appID])
        let others = buttons.keys.compactMap { key -> (id: String, center: CGFloat)? in
            guard let spec = specs[key], spec.isPinned, seen.insert(spec.appID).inserted,
                  let view = buttons.views[key] else { return nil }
            return (spec.appID, view.frame.midX)
        }
        commit(state.pins.moving(appID, before: TaskbarReorder.anchor(draggedCenter: center, others: others)))
    }

    private func scroll(to index: Int) {
        firstIndex = index
        present()
    }

    private func buildContent(in background: DSCard, switchTitle: String) {
        let logo = HobowareLogo.image(height: DSIconSize.startLogo, style: .official, ink: .forDarkBackground)
        let startButton = DSButton(title: logo == nil ? "⊞" : "", image: logo, height: .taskbar, tip: "Start")
        startButton.iconSide = DSIconSize.startLogo
        startButton.onPress = { [weak self] in
            self?.actions.onStart?()
        }

        let filesButton = DSButton(image: HoboIcon.files.image(side: DSIconSize.startLogo), height: .taskbar, tip: "Files")
        filesButton.iconSide = DSIconSize.startLogo
        filesButton.onPress = { [weak self] in
            self?.actions.onFiles?()
        }

        previousButton.onPress = { [weak self] in
            guard let self else { return }
            self.scroll(to: TaskbarOverflow.previousFirstIndex(of: self.page))
        }
        nextButton.onPress = { [weak self] in
            guard let self else { return }
            self.scroll(to: TaskbarOverflow.nextFirstIndex(of: self.page))
        }
        previousButton.isHidden = true
        nextButton.isHidden = true

        itemStack.orientation = .horizontal
        itemStack.spacing = Self.itemSpacing
        itemStack.setHuggingPriority(.defaultHigh, for: .horizontal)

        let showDesktopButton = DSButton(height: .taskbar, width: Self.showDesktopWidth, tip: "Show desktop")
        showDesktopButton.restingFill = DSColor.faint
        showDesktopButton.cornerRadius = DSRadius.none
        showDesktopButton.onPress = { [weak self] in
            self?.actions.onShowDesktop?()
        }

        let root = NSStackView()
        root.orientation = .horizontal
        root.spacing = Self.itemSpacing
        root.edgeInsets = NSEdgeInsets(top: 0, left: DSSpacing.s, bottom: 0, right: 0)
        root.addView(startButton, in: .leading)
        root.addView(filesButton, in: .leading)
        root.addView(previousButton, in: .leading)
        root.addView(itemStack, in: .leading)
        root.addView(nextButton, in: .leading)
        root.addView(SystemTrayView(clockOnOneLine: false, height: .regular), in: .trailing)
        root.addView(showDesktopButton, in: .trailing)

        DSPanelStyle.pin(root, to: background)
        background.menu = ShellContextMenu(
            switchTitle: switchTitle,
            grouping: ShellContextMenu.GroupingChoice(
                current: { [weak self] in self?.grouping ?? .whenFull },
                choose: { [weak self] choice in
                    self?.grouping = choice
                    TaskbarPinStore.save(choice)
                    self?.present()
                }
            )
        ) { [weak self] in
            self?.actions.onSwitchVariant?()
        }
    }
}
