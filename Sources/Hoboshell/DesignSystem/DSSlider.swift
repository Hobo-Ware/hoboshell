import AppKit

final class DSSlider: NSSlider {
    var onChange: ((Double) -> Void)?

    init() {
        super.init(frame: .zero)
        minValue = 0
        maxValue = 1
        isContinuous = true
        trackFillColor = DSColor.accent
        target = self
        action = #selector(valueChanged)
        translatesAutoresizingMaskIntoConstraints = false
        setContentHuggingPriority(.defaultLow, for: .horizontal)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    @objc private func valueChanged() {
        onChange?(doubleValue)
    }
}
