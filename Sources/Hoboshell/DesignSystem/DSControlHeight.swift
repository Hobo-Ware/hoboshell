import CoreGraphics

enum DSControlHeight {
    case compact
    case row
    case regular
    case taskbar

    var value: CGFloat {
        switch self {
        case .compact: return 24
        case .row: return 28
        case .regular: return 32
        case .taskbar: return 40
        }
    }

    var iconSide: CGFloat {
        switch self {
        case .compact: return DSIconSize.inline
        case .row: return DSIconSize.row
        case .regular: return DSIconSize.toolbar
        case .taskbar: return DSIconSize.taskbar
        }
    }

    var textStyle: DSTextStyle {
        self == .compact ? .caption : .body
    }

    var gap: CGFloat {
        self == .compact ? DSSpacing.xs : DSSpacing.s
    }
}
