import Testing
@testable import HoboshellCore

@Suite struct ShellSpeedTests {
    private static let eventsPerDerivation = 25

    private static func busyState(apps: Int, windowsPerApp: Int) -> ShellState {
        var state = ShellState()
        for pid in 1...Int32(apps) {
            state.apply(ShellEvent(.appLaunched(Shell.app(pid, active: pid == 1))))
            let windows = (0..<windowsPerApp).map { Shell.window(Int(pid) * 1_000 + $0, pid) }
            state.apply(ShellEvent(.appSnapshot(pid: pid, windows: windows, reason: .launch)))
        }
        return state
    }

    @Test func tenThousandEventsAndModelDerivationsRunUnderTwoHundredFiftyMilliseconds() {
        var state = Self.busyState(apps: 12, windowsPerApp: 4)
        let clock = ContinuousClock()
        var sink = 0
        let elapsed = clock.measure {
            for step in 0..<10_000 {
                let pid = Int32(step % 12) + 1
                let id = Int(pid) * 1_000 + step % 4
                let kind: ShellEvent.Kind
                switch step % 5 {
                case 0: kind = .windowTitleChanged(id: id, title: "t\(step)")
                case 1: kind = .windowMinimized(id: id)
                case 2: kind = .windowRestored(id: id)
                case 3: kind = .windowFocused(id: id)
                default: kind = .appActivated(pid: pid)
                }
                state.apply(ShellEvent(kind))
                guard step % Self.eventsPerDerivation == 0 else { continue }
                sink += TaskbarModel.make(state, grouping: .whenFull, availableWidth: 1_400, spacing: 4).count
                sink += TrayModel.backgroundApps(state, excluded: []).count
                sink += SwitcherModel.entries(state).count
            }
        }
        #expect(sink > 0)
        #expect(elapsed < .milliseconds(250))
    }

    @Test func derivingTheTaskbarForThreeHundredWindowsTakesUnderFiveMilliseconds() {
        let state = Self.busyState(apps: 30, windowsPerApp: 10)
        let clock = ContinuousClock()
        var count = 0
        let elapsed = clock.measure {
            count = TaskbarModel.make(state, grouping: .whenFull, availableWidth: 1_400, spacing: 4).count
        }
        #expect(count > 0)
        #expect(elapsed < .milliseconds(5))
    }

    @Test func applyingAThousandSnapshotsOfThreeHundredWindowsStaysFast() {
        var state = Self.busyState(apps: 30, windowsPerApp: 10)
        let windows = (0..<10).map { Shell.window(1_000 + $0, 1) }
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for _ in 0..<1_000 {
                state.apply(ShellEvent(.appSnapshot(pid: 1, windows: windows, reason: .sweep)))
            }
        }
        #expect(elapsed < .milliseconds(250))
    }
}
