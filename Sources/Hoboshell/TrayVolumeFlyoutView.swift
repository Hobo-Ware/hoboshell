import AppKit
import CoreAudio
import HoboshellCore

final class TrayVolumeFlyoutView: NSView {
    private let context: TrayFlyoutContext
    private let slider = DSSlider()
    private let muteButton = DSButton(symbol: "speaker.fill", tip: "Mute", height: .regular)
    private let percent = DSLabel("", style: .caption, color: DSColor.dimText, monospacedDigits: true)
    private var stack: NSStackView?
    private var layoutKey = ""
    private var observer: NSObjectProtocol?

    init(context: TrayFlyoutContext) {
        self.context = context
        super.init(frame: .zero)
        slider.onChange = { value in
            TrayVolumeControl.shared.setVolume(Float(value))
        }
        muteButton.onPress = {
            guard let state = TrayVolumeControl.shared.state() else { return }
            TrayVolumeControl.shared.setMuted(!state.isMuted)
        }
        percent.alignment = .right
        percent.translatesAutoresizingMaskIntoConstraints = false
        percent.widthAnchor.constraint(equalToConstant: DSControlHeight.regular.value).isActive = true
        reload()
        observer = NotificationCenter.default.addObserver(
            forName: TrayVolumeControl.didChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.reload()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func reload() {
        let state = TrayVolumeControl.shared.state()
        let key = Self.layoutKey(of: state)
        if key != layoutKey {
            layoutKey = key
            rebuild(state)
            context.refit()
        }
        refresh(state)
    }

    private func refresh(_ state: TrayVolumeState?) {
        let level = state?.level ?? 0
        slider.doubleValue = Double(level)
        slider.isEnabled = state?.canSetVolume ?? false
        percent.stringValue = TrayVolume.percentText(level)
        muteButton.image = DSIconSize.symbol(
            TrayVolume.symbol(level: level, isMuted: state?.isMuted ?? false), description: "Mute"
        )
        muteButton.isSelected = state?.isMuted ?? false
    }

    private func rebuild(_ state: TrayVolumeState?) {
        stack?.removeFromSuperview()
        let controls = NSStackView(views: [muteButton, slider, percent])
        controls.orientation = .horizontal
        controls.spacing = DSSpacing.s
        controls.alignment = .centerY
        var rows: [NSView] = [controls]
        if state?.canSetVolume == false {
            rows.append(DSLabel("This output has no software volume.", style: .caption, color: DSColor.dimText))
        }
        rows.append(DSDivider())
        rows.append(DSSectionHeader("Output"))
        rows.append(contentsOf: (state?.devices ?? []).map { makeRow($0, isCurrent: $0.id == state?.currentDeviceID) })
        rows.append(DSDivider())
        rows.append(TraySettings.button(title: "Sound settings", pane: TraySettings.sound, context: context))

        let next = TrayFlyoutStack.make(rows, spacing: DSSpacing.xs)
        next.translatesAutoresizingMaskIntoConstraints = false
        addSubview(next)
        NSLayoutConstraint.activate([
            next.leadingAnchor.constraint(equalTo: leadingAnchor),
            next.trailingAnchor.constraint(equalTo: trailingAnchor),
            next.topAnchor.constraint(equalTo: topAnchor),
            next.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
        stack = next
    }

    private func makeRow(_ device: TrayVolumeDevice, isCurrent: Bool) -> NSView {
        let tick = isCurrent
            ? DSIconSize.symbol("checkmark")
            : NSImage(size: NSSize(width: DSIconSize.row, height: DSIconSize.row))
        let row = DSListRow(title: device.name, image: tick, height: .row)
        row.onPress = {
            TrayVolumeControl.shared.setOutputDevice(device.id)
        }
        return row
    }

    private static func layoutKey(of state: TrayVolumeState?) -> String {
        guard let state else { return "none" }
        let devices = state.devices.map { "\($0.id):\($0.name)" }.joined(separator: ",")
        return "\(state.currentDeviceID)|\(state.canSetVolume)|\(devices)"
    }
}
