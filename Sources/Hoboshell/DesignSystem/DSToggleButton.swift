import AppKit

final class DSToggleButton: DSButton {
    var onToggle: ((Bool) -> Void)?

    var isOn: Bool {
        get { isSelected }
        set { isSelected = newValue }
    }

    override func activate() {
        isOn.toggle()
        onToggle?(isOn)
        super.activate()
    }
}
