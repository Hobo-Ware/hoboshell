import AppKit

final class DSSegmentedSwitch: NSView {
    struct Segment {
        let symbol: String
        let tip: String
    }

    var onChange: ((Int) -> Void)?

    var selectedIndex: Int {
        didSet { showSelection() }
    }

    var isEnabled = true {
        didSet {
            buttons.forEach { $0.isEnabled = isEnabled }
        }
    }

    private let buttons: [DSButton]

    init(segments: [Segment], selectedIndex: Int = 0, height: DSControlHeight = .regular) {
        self.selectedIndex = selectedIndex
        buttons = segments.map { DSButton(symbol: $0.symbol, tip: $0.tip, height: height) }
        super.init(frame: .zero)
        wantsLayer = true
        layer?.cornerRadius = DSRadius.control
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = DSColor.border.cgColor
        layer?.backgroundColor = DSColor.field.cgColor

        let row = NSStackView(views: buttons)
        row.orientation = .horizontal
        row.spacing = 0
        row.translatesAutoresizingMaskIntoConstraints = false
        addSubview(row)
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.topAnchor.constraint(equalTo: topAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        for (index, button) in buttons.enumerated() {
            button.cornerRadius = DSRadius.none
            button.onPress = { [weak self] in
                self?.choose(index)
            }
        }
        setContentHuggingPriority(.required, for: .horizontal)
        setContentHuggingPriority(.required, for: .vertical)
        showSelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func choose(_ index: Int) {
        guard index != selectedIndex else { return }
        selectedIndex = index
        onChange?(index)
    }

    private func showSelection() {
        for (index, button) in buttons.enumerated() {
            button.isSelected = index == selectedIndex
        }
    }
}
