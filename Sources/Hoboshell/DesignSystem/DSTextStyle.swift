import AppKit

enum DSTextStyle {
    case caption
    case body
    case title

    var size: CGFloat {
        switch self {
        case .caption: return 11
        case .body: return 13
        case .title: return 15
        }
    }

    var lineHeight: CGFloat {
        let font = self.font()
        return ceil(font.ascender - font.descender + font.leading)
    }

    func font(_ weight: DSTextWeight = .regular, monospacedDigits: Bool = false) -> NSFont {
        monospacedDigits
            ? .monospacedDigitSystemFont(ofSize: size, weight: weight.fontWeight)
            : .systemFont(ofSize: size, weight: weight.fontWeight)
    }
}
