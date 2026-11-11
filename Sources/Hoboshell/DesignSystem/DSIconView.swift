import AppKit

final class DSIconView: NSImageView {
    var side: CGFloat {
        didSet { sideConstraints.forEach { $0.constant = side } }
    }

    private var sideConstraints: [NSLayoutConstraint] = []

    init(side: CGFloat, image: NSImage? = nil, tint: NSColor = DSColor.text) {
        self.side = side
        super.init(frame: .zero)
        self.image = image
        imageScaling = .scaleProportionallyUpOrDown
        contentTintColor = tint
        translatesAutoresizingMaskIntoConstraints = false
        sideConstraints = [widthAnchor.constraint(equalToConstant: side), heightAnchor.constraint(equalToConstant: side)]
        NSLayoutConstraint.activate(sideConstraints)
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
