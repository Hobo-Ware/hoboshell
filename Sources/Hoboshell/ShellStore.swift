import Foundation
import HoboshellCore
import os

final class ShellStore {
    static let shared = ShellStore()

    struct Update {
        let state: ShellState
        let change: ShellChange
        let event: ShellEvent?
    }

    private static let driftLog = Logger(subsystem: "dev.hoboware.hoboshell", category: "drift")

    private(set) var state = ShellState(pins: TaskbarPinStore.loadPins())
    private var subscribers: [(Update) -> Void] = []

    func subscribe(_ body: @escaping (Update) -> Void) {
        subscribers.append(body)
    }

    static func post(_ kind: ShellEvent.Kind, observedAt: UInt64 = ShellClock.now()) {
        DispatchQueue.main.async {
            shared.apply(ShellEvent(kind, observedAt: observedAt))
        }
    }

    func apply(_ event: ShellEvent) {
        let change = state.apply(event)
        for line in change.drift {
            Self.driftLog.notice("missed event: \(line, privacy: .public)")
        }
        guard !change.isEmpty else { return }
        notify(Update(state: state, change: change, event: event))
        PerfLog.shown(event)
    }

    func refresh() {
        notify(Update(state: state, change: ShellChange(), event: nil))
    }

    private func notify(_ update: Update) {
        for subscriber in subscribers {
            subscriber(update)
        }
    }
}
