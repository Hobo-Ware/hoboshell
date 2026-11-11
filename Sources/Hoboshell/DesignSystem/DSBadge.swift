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

    init(_ text: String, tone: Tone = .neutral) {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = DSRadius.control
        layer?.backgroundColor = tone.fill.cgColor
        translatesAutoresizingMaskIntoConstraints = false
        let label = DSLabel(text, style: .caption, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: DSSpacing.s),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -DSSpacing.s),
            label.topAnchor.constraint(equalTo: topAnchor, constant: DSSpacing.xxs),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -DSSpacing.xxs),
        ])
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
