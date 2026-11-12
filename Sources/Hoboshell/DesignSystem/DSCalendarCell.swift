import AppKit

final class DSCalendarCell: DSControl {
    enum Style {
        case day
        case today
        case weekNumber
        case weekday
        case blank
    }

    static let side = DSControlHeight.row.value

    init(_ text: String, style: Style) {
        super.init(frame: .zero)
        handlesClicks = false
        tracksHover = false
        translatesAutoresizingMaskIntoConstraints = false
        if style == .today {
            restingFill = DSColor.accent
        }
        let label = DSLabel(text, style: style == .weekday ? .caption : .body, weight: style == .today ? .semibold : .regular, color: Self.color(style), monospacedDigits: true)
        label.alignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            widthAnchor.constraint(equalToConstant: Self.side),
            heightAnchor.constraint(equalToConstant: Self.side),
        ])
        setAccessibilityLabel(text)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private static func color(_ style: Style) -> NSColor {
        switch style {
        case .day, .blank: return DSColor.text
        case .today: return DSColor.onAccent
        case .weekNumber, .weekday: return DSColor.dimText
        }
    }
}
