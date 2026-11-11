import AppKit

enum DSMotion {
    enum Kind {
        case hover
        case menu
    }

    static var isReduced: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    static func duration(_ kind: Kind) -> TimeInterval {
        guard !isReduced else { return 0 }
        switch kind {
        case .hover: return 0.12
        case .menu: return 0.18
        }
    }

    static func fill(_ layer: CALayer, to color: CGColor?, kind: Kind = .hover) {
        let length = duration(kind)
        if length > 0, let from = layer.presentation()?.backgroundColor {
            let animation = CABasicAnimation(keyPath: "backgroundColor")
            animation.fromValue = from
            animation.toValue = color
            animation.duration = length
            layer.add(animation, forKey: "dsFill")
        }
        layer.backgroundColor = color
    }
}
