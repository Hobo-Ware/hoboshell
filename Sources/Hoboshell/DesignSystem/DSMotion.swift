import AppKit

enum DSMotion {
    enum Kind {
        case hoverIn
        case hoverOut
        case presence
        case menu
    }

    static var isReduced: Bool {
        NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
    }

    static func duration(_ kind: Kind) -> TimeInterval {
        guard !isReduced else { return 0 }
        switch kind {
        case .hoverIn: return 0
        case .hoverOut: return 0.08
        case .presence: return 0.12
        case .menu: return 0.18
        }
    }

    static func fill(_ layer: CALayer, to color: CGColor?, kind: Kind = .hoverOut) {
        let length = duration(kind)
        if length == 0 {
            layer.removeAnimation(forKey: "dsFill")
        }
        if length > 0, let from = layer.presentation()?.backgroundColor {
            let animation = CABasicAnimation(keyPath: "backgroundColor")
            animation.fromValue = from
            animation.toValue = color
            animation.duration = length
            layer.add(animation, forKey: "dsFill")
        }
        layer.backgroundColor = color
    }

    static func appear(_ view: NSView) {
        let length = duration(.presence)
        guard length > 0 else { return }
        view.alphaValue = 0
        NSAnimationContext.runAnimationGroup { context in
            context.duration = length
            view.animator().alphaValue = 1
        }
    }

    static func disappear(_ view: NSView) {
        let length = duration(.presence)
        guard length > 0 else {
            view.removeFromSuperview()
            return
        }
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = length
            view.animator().alphaValue = 0
        }, completionHandler: {
            view.removeFromSuperview()
        })
    }
}
