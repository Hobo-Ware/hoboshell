import AppKit

final class DSDivider: NSView {
    enum Axis {
        case horizontal
        case vertical
    }

    private static let thickness: CGFloat = 1

    init(_ axis: Axis = .horizontal) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = DSColor.border.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        switch axis {
        case .horizontal:
            heightAnchor.constraint(equalToConstant: Self.thickness).isActive = true
        case .vertical:
            widthAnchor.constraint(equalToConstant: Self.thickness).isActive = true
            heightAnchor.constraint(equalToConstant: DSIconSize.inline).isActive = true
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
