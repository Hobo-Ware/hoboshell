import AppKit
import HoboshellCore

final class TaskbarTrashButton: DSButton {
    var onDrop: (([URL]) -> Void)?

    private var observer: NSObjectProtocol?

    init() {
        super.init(height: .taskbar, tip: "Trash")
        iconSide = DSIconSize.startLogo
        registerForDraggedTypes([.fileURL])
        onPress = {
            TrashActions.open()
        }
        observer = NotificationCenter.default.addObserver(
            forName: TrashMonitor.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.showCurrentContents()
        }
        showCurrentContents()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard !TrashActions.droppedURLs(in: sender).isEmpty else { return [] }
        isSelected = true
        return .move
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        isSelected ? .move : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        isSelected = false
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        isSelected = false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = TrashActions.droppedURLs(in: sender)
        guard !urls.isEmpty else { return false }
        onDrop?(urls)
        return true
    }

    private func showCurrentContents() {
        let contents = TrashMonitor.shared.contents
        image = (contents.isFull ? HoboIcon.trashFull : HoboIcon.trashEmpty).image(side: DSIconSize.startLogo)
        setAccessibilityValue(contents.countText)
        menu = DSMenu.make([
            DSMenuItem("Open Trash") { TrashActions.open() },
            DSMenuItem("Empty Trash", isEnabled: contents != .empty) { TrashActions.confirmAndEmpty() },
        ])
    }
}
