import AppKit

final class DSRunMark: NSView {
    enum State {
        case none
        case running
        case active
        case background
    }

    static let height: CGFloat = 3
    static let runningWidth: CGFloat = 12
    static let activeWidth: CGFloat = 20
    static let backgroundSize: CGFloat = 4

    var state = State.none {
        didSet {
            guard oldValue != state else { return }
            refresh()
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
        refresh()
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

    private func refresh() {
        isHidden = state == .none
        let size = Self.size(of: state)
        widthConstraint?.constant = size.width
        heightConstraint?.constant = size.height
        layer?.cornerRadius = size.height / 2
        layer?.backgroundColor = (state == .active ? DSColor.accent : DSColor.runMark).cgColor
    }
}
