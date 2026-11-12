import AppKit
import HoboshellCore

final class TrayBatteryFlyoutView: NSView {
    init(context: TrayFlyoutContext) {
        super.init(frame: .zero)
        var rows: [NSView] = []
        if let battery = TrayBatteryReader.read() {
            rows.append(DSLabel(battery.status.label, style: .title, weight: .semibold))
            rows.append(DSLabel(battery.stateText))
            if let time = battery.timeText {
                rows.append(DSLabel(time, style: .caption, color: DSColor.dimText))
            }
        } else {
            rows.append(DSLabel("This Mac has no battery."))
        }
        let lowPower = DSLabel(
            BatteryDetails.lowPowerModeText(isOn: ProcessInfo.processInfo.isLowPowerModeEnabled),
            style: .caption,
            color: DSColor.dimText
        )
        rows.append(contentsOf: [lowPower, DSDivider(), TraySettings.button(title: "Battery settings", pane: TraySettings.battery, context: context)])

        let stack = TrayFlyoutStack.make(rows, spacing: DSSpacing.xs)
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
