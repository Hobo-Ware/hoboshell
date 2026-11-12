import AppKit
import HoboshellCore

final class RealtimeSelfTest {
    private struct Step {
        let name: String
        let command: ProbeCommand?
        let isDone: () -> Bool
        let verify: () -> String?
        var budget = SelfTestReport.budgetMilliseconds
    }

    // macOS reports a window as minimised or restored only when its animation has ended.
    private static let animatedStepBudget = 1000.0

    private static let stepTimeout: TimeInterval = 3
    private static let pollInterval: TimeInterval = 0.005

    private let engine: ShellEngine
    private let chrome: ShellChrome
    private let reportPath: String?
    private let process = Process()
    private let commandPipe = Pipe()
    private let outputPipe = Pipe()
    private var report = SelfTestReport()
    private var steps: [Step] = []
    private var index = 0
    private var stepStart: UInt64 = 0
    private var pollTimer: Timer?
    private var readyAt: UInt64?
    private var isFinished = false
    private var windowAView: ObjectIdentifier?

    init(engine: ShellEngine, chrome: ShellChrome, reportPath: String?) {
        self.engine = engine
        self.chrome = chrome
        self.reportPath = reportPath
    }

    func start() {
        guard engine.isTrusted else {
            finish(error: "Accessibility access is off for this binary. Grant it in System Settings and run again.")
            return
        }
        guard let probeURL = Self.probeLocation(),
              FileManager.default.isExecutableFile(atPath: probeURL.path) else {
            finish(error: "HoboshellProbe is missing next to the Hoboshell binary. Run swift build first.")
            return
        }
        process.executableURL = probeURL
        process.standardInput = commandPipe
        process.standardOutput = outputPipe
        outputPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let received = ShellClock.now()
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                return
            }
            for line in String(decoding: data, as: UTF8.self).split(separator: "\n") {
                DispatchQueue.main.async { self?.probeSaid(String(line), at: received) }
            }
        }
        process.terminationHandler = { [weak self] _ in
            DispatchQueue.main.async { self?.probeExited() }
        }
        do {
            try process.run()
        } catch {
            finish(error: "could not start HoboshellProbe: \(error.localizedDescription)")
            return
        }
        steps = makeSteps()
        engine.store.subscribe { [weak self] _ in
            self?.evaluate()
        }
        say("realtime self-test started, probe pid \(process.processIdentifier)")
    }

    // Inside the app bundle the helper would count as Hoboshell itself, so it lives next to the bundle.
    private static func probeLocation() -> URL? {
        let name = "HoboshellProbe"
        let besideBundle = Bundle.main.bundleURL.deletingLastPathComponent().appendingPathComponent(name)
        if FileManager.default.isExecutableFile(atPath: besideBundle.path) {
            return besideBundle
        }
        return Bundle.main.executableURL?.deletingLastPathComponent().appendingPathComponent(name)
    }

    private var pid: pid_t { process.processIdentifier }

    private var probeButtons: [TaskbarButtonInfo] {
        chrome.shownButtons.filter { $0.pid == pid }
    }

    private var probeWindowCount: Int {
        probeButtons.reduce(0) { $0 + $1.windowCount }
    }

    private var isInTray: Bool {
        TrayAppsStore.shared.apps.contains { $0.id == "pid:\(pid)" }
    }

    private var probeWindows: [WindowState] {
        engine.store.state.windows.filter { $0.pid == pid }.sorted { $0.id < $1.id }
    }

    private func button(titled title: String) -> TaskbarButtonInfo? {
        probeButtons.first { $0.tip == title }
    }

    private func makeSteps() -> [Step] {
        [
            Step(name: "helper launch shows in the tray or taskbar", command: nil, isDone: { [self] in
                isInTray || !probeButtons.isEmpty
            }, verify: { nil }),
            Step(name: "first window adds a button", command: .open(title: "Probe A"), isDone: { [self] in
                probeWindowCount == 1 && button(titled: "Probe A") != nil && !isInTray
            }, verify: { [self] in
                windowAView = button(titled: "Probe A")?.view
                return nil
            }),
            Step(name: "second window adds a second button", command: .open(title: "Probe B"), isDone: { [self] in
                probeWindowCount == 2
            }, verify: { nil }),
            Step(name: "retitle updates the label in place", command: .retitle(window: 1, title: "Probe A renamed"), isDone: { [self] in
                button(titled: "Probe A renamed") != nil
            }, verify: { [self] in
                button(titled: "Probe A renamed")?.view == windowAView ? nil : "the button was rebuilt instead of updated"
            }),
            Step(name: "minimise keeps the button", command: .minimize(window: 1), isDone: { [self] in
                probeWindows.first?.isMinimized == true
            }, verify: { [self] in
                keepsButtonA()
            }, budget: Self.animatedStepBudget),
            Step(name: "restore keeps the button", command: .restore(window: 1), isDone: { [self] in
                probeWindows.first?.isMinimized == false
            }, verify: { [self] in
                keepsButtonA()
            }, budget: Self.animatedStepBudget),
            Step(name: "close removes the button", command: .close(window: 2), isDone: { [self] in
                probeWindowCount == 1
            }, verify: { [self] in
                keepsButtonA()
            }),
            Step(name: "closing the last window moves the app to the tray", command: .close(window: 1), isDone: { [self] in
                probeButtons.isEmpty && isInTray
            }, verify: { nil }),
            Step(name: "helper quit removes it from the tray", command: .quit, isDone: { [self] in
                !isInTray && probeButtons.isEmpty && engine.store.state.app(pid: pid) == nil
            }, verify: { nil }),
        ]
    }

    private func keepsButtonA() -> String? {
        probeButtons.contains { $0.view == windowAView } ? nil : "the button for the first window disappeared"
    }

    private func probeSaid(_ line: String, at received: UInt64) {
        say("probe: \(line)")
        guard line == "ready", readyAt == nil else { return }
        readyAt = received
        begin(step: 0, from: received)
    }

    private func begin(step number: Int, from start: UInt64) {
        index = number
        stepStart = start
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: Self.pollInterval, repeats: true) { [weak self] _ in
            self?.evaluate()
        }
        if let command = steps[number].command {
            send(command)
        }
        evaluate()
    }

    private func send(_ command: ProbeCommand) {
        commandPipe.fileHandleForWriting.write(Data((command.line + "\n").utf8))
    }

    private func evaluate() {
        guard !isFinished, readyAt != nil, steps.indices.contains(index) else { return }
        let step = steps[index]
        let elapsed = ShellClock.milliseconds(since: stepStart)
        if step.isDone() {
            record(SelfTestStep(name: step.name, milliseconds: elapsed, failure: step.verify(), budgetMilliseconds: step.budget))
        } else if elapsed > Self.stepTimeout * 1_000 {
            record(SelfTestStep(name: step.name, milliseconds: nil, failure: "timed out after \(Int(Self.stepTimeout)) s"))
        }
    }

    private func record(_ step: SelfTestStep) {
        pollTimer?.invalidate()
        report.add(step)
        say(report.line(for: report.steps.count - 1))
        let next = index + 1
        guard steps.indices.contains(next) else {
            finish(error: nil)
            return
        }
        index = steps.count
        DispatchQueue.main.async { [weak self] in
            self?.begin(step: next, from: ShellClock.now())
        }
    }

    private func probeExited() {
        guard readyAt == nil else { return }
        finish(error: "HoboshellProbe exited before it was ready")
    }

    private func finish(error: String?) {
        guard !isFinished else { return }
        isFinished = true
        pollTimer?.invalidate()
        if process.isRunning {
            process.terminate()
        }
        if let error {
            say("realtime self-test could not run: \(error)")
            exit(2)
        }
        say(report.summary)
        if let reportPath {
            do {
                try report.text.write(toFile: reportPath, atomically: true, encoding: .utf8)
            } catch {
                say("could not write the report to \(reportPath): \(error.localizedDescription)")
            }
        }
        exit(report.allPassed ? 0 : 1)
    }

    private func say(_ text: String) {
        print(text)
        fflush(stdout)
    }
}
