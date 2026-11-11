import AppKit

enum DSTextWeight {
    case regular
    case medium
    case semibold

    var fontWeight: NSFont.Weight {
        switch self {
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        }
    }
}
