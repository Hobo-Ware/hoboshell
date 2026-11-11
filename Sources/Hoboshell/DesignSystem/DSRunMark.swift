import AppKit

final class DSRunMark: NSView {
    enum State {
        case none
        case running
        case active
    }

    static let height: CGFloat = 3
    static let runningWidth: CGFloat = 12
    static let activeWidth: CGFloat = 20

    var state = State.none {
        didSet {
            guard oldValue != state else { return }
            refresh()
        }
    }

    private var widthConstraint: NSLayoutConstraint?

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = Self.height / 2
        translatesAutoresizingMaskIntoConstraints = false
        let width = widthAnchor.constraint(equalToConstant: Self.runningWidth)
        widthConstraint = width
        NSLayoutConstraint.activate([width, heightAnchor.constraint(equalToConstant: Self.height)])
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func refresh() {
        isHidden = state == .none
        widthConstraint?.constant = state == .active ? Self.activeWidth : Self.runningWidth
        layer?.backgroundColor = (state == .active ? DSColor.accent : DSColor.runMark).cgColor
    }
}
