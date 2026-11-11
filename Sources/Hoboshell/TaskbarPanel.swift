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
    private var snapshot = TaskbarSnapshot(items: [])
    private var shownKey = ""
    private var pins = TaskbarPinStore.loadPins()
    private var grouping = TaskbarPinStore.loadGrouping()
    private var firstIndex = 0
    private var isReordering = false
    private var page = TaskbarPage(range: 0..<0, overflows: false, hasPrevious: false, hasNext: false)
    private var buttons: [(model: TaskbarButtonModel, view: TaskbarButton)] = []
    private let previewCard = PreviewCardPanel()

    init(layout: ShellLayout, switchTitle: String) {
        super.init(contentRect: layout.bar, styleMask: DSPanelStyle.styleMask, backing: .buffered, defer: false)
        buildContent(in: DSPanelStyle.apply(to: self, kind: .bar), switchTitle: switchTitle)
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
        rebuild(force: true)
    }

    func startMenuOrigin(menuSize: NSSize) -> NSPoint {
        NSPoint(x: frame.minX + DSSpacing.s, y: frame.maxY + DSSpacing.s)
    }

    func update(items: [TaskbarItem]) {
        update(snapshot: TaskbarSnapshot(items: items))
    }

    func update(snapshot: TaskbarSnapshot) {
        self.snapshot = snapshot
        rebuild(force: false)
    }

    private func rebuild(force: Bool) {
        guard !isReordering else { return }
        let available = frame.width - Self.widthUsedByFixedControls
        let slots = TaskbarSlots.arrange(
            pins: pins,
            windowApps: snapshot.items.enumerated().map { $0.element.appID ?? "item:\($0.offset)" },
            runningApps: Set(snapshot.apps.map(\.id)),
            grouping: grouping,
            availableWidth: available,
            spacing: Self.itemSpacing
        )
        let models = TaskbarButtonModels.make(slots: slots, snapshot: snapshot)

        let iconOnlyCount = models.filter(\.isIconOnly).count
        let labelledCount = models.count - iconOnlyCount
        let labelledWidth = TaskbarLayout.buttonWidth(
            buttonCount: labelledCount,
            availableWidth: available - CGFloat(iconOnlyCount) * (TaskbarLayout.iconOnlyWidth + Self.itemSpacing),
            spacing: Self.itemSpacing
        )
        let usesLabels = labelledCount > 0 && TaskbarLayout.showsTitle(atWidth: labelledWidth)
        let nextPage = usesLabels
            ? TaskbarPage(range: 0..<models.count, overflows: false, hasPrevious: false, hasNext: false)
            : TaskbarOverflow.page(
                buttonCount: models.count,
                buttonWidth: TaskbarLayout.iconOnlyWidth,
                availableWidth: available,
                spacing: Self.itemSpacing,
                arrowWidth: DSControlHeight.taskbar.value,
                firstIndex: firstIndex
            )
        firstIndex = nextPage.range.lowerBound

        let key = ([
            "\(usesLabels)", "\(labelledWidth)", "\(nextPage.range)", "\(grouping)", "\(pins.ids)",
        ] + models[nextPage.range].map(\.key)).joined(separator: "|")
        guard force || key != shownKey else { return }
        shownKey = key
        page = nextPage

        previewCard.dismiss()
        itemStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons = []
        for model in models[nextPage.range] {
            let button = makeButton(for: model, labelled: usesLabels && !model.isIconOnly, width: labelledWidth)
            itemStack.addArrangedSubview(button)
            buttons.append((model, button))
        }
        previousButton.isHidden = !nextPage.overflows
        nextButton.isHidden = !nextPage.overflows
        previousButton.isEnabled = nextPage.hasPrevious
        nextButton.isEnabled = nextPage.hasNext
    }

    private func makeButton(for model: TaskbarButtonModel, labelled: Bool, width: CGFloat) -> TaskbarButton {
        let button = TaskbarItemView.make(
            icon: model.icon,
            title: labelled ? model.title : nil,
            isActive: model.isActive,
            runState: model.runState,
            width: labelled ? width : TaskbarLayout.iconOnlyWidth
        ) { }
        button.onPress = { [weak self, weak button] in
            guard let self, let button else { return }
            self.press(model, button: button)
        }
        button.toolTip = model.title
        button.setAccessibilityLabel(model.title)
        button.countText = model.isGroup ? "\(model.items.count)" : nil
        button.notificationText = model.badge
        button.menu = TaskbarMenu.make(for: model) { [weak self] in
            self?.togglePin(model.appID)
        }
        button.isReorderable = model.slot.isPinned
        button.onReorderingChange = { [weak self] isDragging in
            self?.isReordering = isDragging
        }
        button.onReorder = { [weak self] center in
            self?.reorder(model.appID, droppedAt: center)
        }
        button.onDragHover = { model.revealWindow?() }
        if !model.items.isEmpty {
            button.onHoverChange = { [weak self, weak button] isInside in
                guard let self, let button, isInside else {
                    self?.previewCard.pointerLeft()
                    return
                }
                self.previewCard.pointerEntered(model.items, anchor: self.anchor(of: button), screen: self.screenFrame)
            }
        }
        return button
    }

    private var screenFrame: NSRect {
        screen?.frame ?? frame
    }

    private func anchor(of button: NSView) -> NSRect {
        convertToScreen(button.convert(button.bounds, to: nil))
    }

    private func press(_ model: TaskbarButtonModel, button: TaskbarButton) {
        if model.isGroup {
            previewCard.showNow(model.items, anchor: anchor(of: button), screen: screenFrame)
            return
        }
        previewCard.dismiss()
        if let item = model.items.first {
            item.activate()
        } else if let activateApp = model.activateApp {
            activateApp()
        } else {
            model.launch?()
        }
    }

    private func togglePin(_ appID: String) {
        pins = pins.contains(appID) ? pins.removing(appID) : pins.adding(appID)
        TaskbarPinStore.save(pins)
        rebuild(force: true)
    }

    private func reorder(_ appID: String, droppedAt center: CGFloat) {
        var seen = Set([appID])
        let others = buttons.compactMap { entry -> (id: String, center: CGFloat)? in
            guard entry.model.slot.isPinned, seen.insert(entry.model.appID).inserted else { return nil }
            return (entry.model.appID, entry.view.frame.midX)
        }
        pins = pins.moving(appID, before: TaskbarReorder.anchor(draggedCenter: center, others: others))
        TaskbarPinStore.save(pins)
        rebuild(force: true)
    }

    private func scroll(to index: Int) {
        firstIndex = index
        rebuild(force: true)
    }

    private func buildContent(in background: DSCard, switchTitle: String) {
        let logo = HobowareLogo.image(height: DSIconSize.startLogo, style: .official, ink: .forDarkBackground)
        let startButton = DSButton(title: logo == nil ? "⊞" : "", image: logo, height: .taskbar, tip: "Start")
        startButton.onPress = { [weak self] in
            self?.actions.onStart?()
        }

        let filesButton = DSButton(symbol: "folder.fill", tip: "Files", height: .taskbar)
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
                    self?.rebuild(force: true)
                }
            )
        ) { [weak self] in
            self?.actions.onSwitchVariant?()
        }
    }
}
