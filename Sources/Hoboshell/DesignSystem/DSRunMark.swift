import AppKit

final class DSRunMark: NSView {
    enum State {
        case none
        case running
        case active
        case background
    }

    static let height: CGFloat = 3
    static let runningWidth: CGFloat = 6
    static let activeWidth: CGFloat = 18
    static let backgroundSize: CGFloat = 4

    var state = State.none {
        didSet {
            guard oldValue != state else { return }
            refresh(from: oldValue)
        }
    }

    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = Self.height / 2
        translatesAutoresizingMaskIntoConstraints = false
        let width = widthAnchor.constraint(equalToConstant: Self.runningWidth)
        widthConstraint = width
        let height = heightAnchor.constraint(equalToConstant: Self.height)
        heightConstraint = height
        NSLayoutConstraint.activate([width, height])
        refresh(from: .none)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private static func size(of state: State) -> CGSize {
        switch state {
        case .none, .running: return CGSize(width: runningWidth, height: height)
        case .active: return CGSize(width: activeWidth, height: height)
        case .background: return CGSize(width: backgroundSize, height: backgroundSize)
        }
    }

    private func refresh(from old: State) {
        isHidden = state == .none
        let size = Self.size(of: state)
        let color = (state == .active ? DSColor.accent : DSBarColor.runLine).cgColor
        let grows = window != nil && old != .none && state != .none
        let length = grows ? DSMotion.duration(.grow) : 0
        layer?.cornerRadius = size.height / 2
        if let layer {
            DSMotion.fill(layer, to: color, kind: .grow)
        }
        guard length > 0 else {
            widthConstraint?.constant = size.width
            heightConstraint?.constant = size.height
            return
        }
        NSAnimationContext.runAnimationGroup { context in
            context.duration = length
            context.allowsImplicitAnimation = true
            widthConstraint?.animator().constant = size.width
            heightConstraint?.animator().constant = size.height
        }
    }
}
