import AppKit

final class DSBadge: NSView {
    enum Tone {
        case neutral
        case accent
        case danger

        var fill: NSColor {
            switch self {
            case .neutral: return DSColor.selected
            case .accent: return DSColor.accent
            case .danger: return DSColor.danger
            }
        }
    }

    enum Size {
        case regular
        case compact

        var horizontalPadding: CGFloat {
            self == .regular ? DSSpacing.s : DSSpacing.xs
        }

        var verticalPadding: CGFloat {
            self == .regular ? DSSpacing.xxs : 0
        }
    }

    init(_ text: String, tone: Tone = .neutral, size: Size = .regular) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = DSRadius.control
        layer?.backgroundColor = tone.fill.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        let label = DSLabel(text, style: .caption, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: size.horizontalPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -size.horizontalPadding),
            label.topAnchor.constraint(equalTo: topAnchor, constant: size.verticalPadding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -size.verticalPadding),
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
