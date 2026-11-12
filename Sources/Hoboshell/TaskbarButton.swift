import AppKit
import HoboshellCore

final class TaskbarButton: DSTaskbarButton {
    private static let dragHoverDelay: TimeInterval = 0.6

    var isReorderable = false
    var onReorder: ((CGFloat) -> Void)?
    var onReorderingChange: ((Bool) -> Void)?
    var onDragHover: (() -> Void)?

    private var pressX: CGFloat?
    private var isReordering = false
    private var dragHoverTimer: Timer?

    override init(
        title: String = "",
        image: NSImage? = nil,
        views: [NSView] = [],
        height: DSControlHeight = .taskbar,
        width: CGFloat? = nil,
        alignment: Alignment = .center,
        tip: String? = nil
    ) {
        super.init(title: title, image: image, views: views, height: height, width: width, alignment: alignment, tip: tip)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func mouseDown(with event: NSEvent) {
        pressX = event.locationInWindow.x
        super.mouseDown(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isReorderable, let pressX else {
            super.mouseDragged(with: event)
            return
        }
        let offset = event.locationInWindow.x - pressX
        if !isReordering {
            guard abs(offset) >= TaskbarReorder.dragThreshold else {
                super.mouseDragged(with: event)
                return
            }
            isReordering = true
            cancelPress()
            onReorderingChange?(true)
        }
        layer?.transform = CATransform3DMakeTranslation(offset, 0, 0)
    }

    override func mouseUp(with event: NSEvent) {
        defer { pressX = nil }
        guard isReordering, let pressX else {
            super.mouseUp(with: event)
            return
        }
        isReordering = false
        layer?.transform = CATransform3DIdentity
        onReorderingChange?(false)
        onReorder?(frame.midX + event.locationInWindow.x - pressX)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        dragHoverTimer?.invalidate()
        dragHoverTimer = Timer.scheduledTimer(withTimeInterval: Self.dragHoverDelay, repeats: false) { [weak self] _ in
            self?.onDragHover?()
        }
        return []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        cancelDragHover()
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        cancelDragHover()
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        false
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        false
    }

    private func cancelDragHover() {
        dragHoverTimer?.invalidate()
        dragHoverTimer = nil
    }
}
