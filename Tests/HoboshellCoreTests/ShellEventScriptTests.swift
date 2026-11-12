import Testing
@testable import HoboshellCore

@Suite struct ShellEventScriptTests {
    private struct Picture: Equatable {
        let taskbar: [String]
        let tray: [String]
        let switcher: [Int]
    }

    private func picture(_ state: ShellState) -> Picture {
        Picture(
            taskbar: Shell.buttons(state).map { "\($0.id):\($0.title):\($0.isActive ? "on" : "off")" },
            tray: TrayModel.backgroundApps(state, excluded: []).map(\.name),
            switcher: SwitcherModel.entries(state).map(\.windowID)
        )
    }

    private func run(_ steps: [(ShellEvent.Kind, Picture)]) {
        var state = ShellState()
        for (index, step) in steps.enumerated() {
            state.apply(ShellEvent(step.0))
            #expect(picture(state) == step.1, "after step \(index + 1)")
        }
    }

    @Test func aTypicalSessionFromLaunchToQuit() {
        let notes = Shell.app(7, "notes", name: "Notes", active: true)
        let steps: [(ShellEvent.Kind, Picture)] = [
            (.appLaunched(notes), Picture(taskbar: [], tray: [], switcher: [])),
            (.appSnapshot(pid: 7, windows: [], reason: .launch), Picture(taskbar: [], tray: ["Notes"], switcher: [])),
            (.windowCreated(Shell.window(1, 7, "One", focused: true)), Picture(taskbar: ["w1:One:on"], tray: [], switcher: [1])),
            (.windowCreated(Shell.window(2, 7, "Two")), Picture(taskbar: ["w1:One:on", "w2:Two:off"], tray: [], switcher: [1, 2])),
            (.windowCreated(Shell.window(3, 7, "Three")), Picture(taskbar: ["w1:One:on", "w2:Two:off", "w3:Three:off"], tray: [], switcher: [1, 2, 3])),
            (.windowFocused(id: 3), Picture(taskbar: ["w1:One:off", "w2:Two:off", "w3:Three:on"], tray: [], switcher: [3, 1, 2])),
            (.windowMinimized(id: 2), Picture(taskbar: ["w1:One:off", "w2:Two:off", "w3:Three:on"], tray: [], switcher: [3, 1, 2])),
            (.windowMinimized(id: 1), Picture(taskbar: ["w1:One:off", "w2:Two:off", "w3:Three:on"], tray: [], switcher: [3, 1, 2])),
            (.windowDestroyed(id: 3), Picture(taskbar: ["w1:One:off", "w2:Two:off"], tray: [], switcher: [1, 2])),
            (.desktopChanged, Picture(taskbar: ["w1:One:off", "w2:Two:off"], tray: [], switcher: [1, 2])),
            (.appSnapshot(pid: 7, windows: [], reason: .desktopChange), Picture(taskbar: [], tray: [], switcher: [])),
            (.appSnapshot(pid: 7, windows: [Shell.window(1, 7, "One", minimized: true), Shell.window(2, 7, "Two", minimized: true)], reason: .desktopChange),
             Picture(taskbar: ["w1:One:off", "w2:Two:off"], tray: [], switcher: [1, 2])),
            (.windowRestored(id: 2), Picture(taskbar: ["w1:One:off", "w2:Two:off"], tray: [], switcher: [1, 2])),
            (.windowDestroyed(id: 1), Picture(taskbar: ["w2:Two:off"], tray: [], switcher: [2])),
            (.windowDestroyed(id: 2), Picture(taskbar: [], tray: ["Notes"], switcher: [])),
            (.appTerminated(pid: 7), Picture(taskbar: [], tray: [], switcher: [])),
        ]
        run(steps)
    }

    @Test func twoAppsTradingTheFrontKeepTheirButtonsStill() {
        let steps: [(ShellEvent.Kind, Picture)] = [
            (.appLaunched(Shell.app(1, "a", name: "A")), Picture(taskbar: [], tray: [], switcher: [])),
            (.appSnapshot(pid: 1, windows: [Shell.window(10, 1, "a1", focused: true)], reason: .launch), Picture(taskbar: ["w10:a1:off"], tray: [], switcher: [10])),
            (.appLaunched(Shell.app(2, "b", name: "B", active: true)), Picture(taskbar: ["w10:a1:off"], tray: [], switcher: [10])),
            (.appSnapshot(pid: 2, windows: [Shell.window(20, 2, "b1", focused: true)], reason: .launch), Picture(taskbar: ["w10:a1:off", "w20:b1:on"], tray: [], switcher: [20, 10])),
            (.appActivated(pid: 1), Picture(taskbar: ["w10:a1:on", "w20:b1:off"], tray: [], switcher: [10, 20])),
            (.appActivated(pid: 2), Picture(taskbar: ["w10:a1:off", "w20:b1:on"], tray: [], switcher: [20, 10])),
            (.appHidden(pid: 2), Picture(taskbar: ["w10:a1:off", "w20:b1:on"], tray: [], switcher: [20, 10])),
            (.appTerminated(pid: 2), Picture(taskbar: ["w10:a1:off"], tray: [], switcher: [10])),
        ]
        run(steps)
    }
}
