import AppKit
import HoboshellCore

final class TrayVolumeButton: DSButton {
    private var scroll = TrayScrollAccumulator()

    override func scrollWheel(with event: NSEvent) {
        guard event.momentumPhase.isEmpty else { return }
        let direction: CGFloat = event.isDirectionInvertedFromDevice ? -1 : 1
        let steps = scroll.add(event.scrollingDeltaY * direction, isPrecise: event.hasPreciseScrollingDeltas)
        guard steps != 0, let state = TrayVolumeControl.shared.state() else { return }
        TrayVolumeControl.shared.setVolume(TrayVolume.stepped(state.level, by: steps))
    }
}
