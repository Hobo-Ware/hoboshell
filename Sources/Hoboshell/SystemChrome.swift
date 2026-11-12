import AppKit
import HoboshellCore

enum SystemChrome {
    static let wantedDidChange = Notification.Name("SystemChromeWantedDidChange")

    private static let savedValuesKey = "SystemChromeSavedValues"
    private static let wantedKey = "HideSystemUI"
    private static var generation = 0
    private static var measurer: DockMeasurer?

    static var isActive: Bool {
        UserDefaults.standard.dictionary(forKey: savedValuesKey) != nil
    }

    static var isWanted: Bool {
        UserDefaults.standard.bool(forKey: wantedKey)
    }

    static func setWanted(_ wanted: Bool) {
        UserDefaults.standard.set(wanted, forKey: wantedKey)
        NotificationCenter.default.post(name: wantedDidChange, object: nil)
    }

    static func engage(variant: ShellVariant, completion: @escaping (DockReservation) -> Void) {
        generation += 1
        let edge = variant.dockEdge
        let target = DockCalibration.targetThickness(for: edge)
        let tileSize = UserDefaults.standard.object(forKey: DockCalibration.storageKey(for: edge)) as? Int
            ?? DockCalibration.startingTileSize(target: target)
        let isFirstEngage = saveCurrentValues()
        apply(DockSettingsPlan.changes(for: edge, tileSize: tileSize))
        calibrate(
            Calibration(edge: edge, target: target, generation: generation),
            tileSize: tileSize,
            round: 1,
            restartsFinder: isFirstEngage,
            completion: completion
        )
    }

    static func restore() {
        generation += 1
        measurer?.cancel()
        measurer = nil
        guard let saved = UserDefaults.standard.dictionary(forKey: savedValuesKey) as? [String: String] else { return }
        apply(DockSettingsPlan.restoreChanges(saved: saved))
        UserDefaults.standard.removeObject(forKey: savedValuesKey)
        UserDefaults.standard.synchronize()
        restartOwners(includingFinder: true)
    }

    private struct Calibration {
        let edge: DockEdge
        let target: CGFloat
        let generation: Int
    }

    private static func calibrate(
        _ calibration: Calibration,
        tileSize: Int,
        round: Int,
        restartsFinder: Bool,
        completion: @escaping (DockReservation) -> Void
    ) {
        measurer = DockMeasurer(edge: calibration.edge) { measured in
            guard calibration.generation == generation else { return }
            measurer = nil
            guard let measured else {
                completion(.off)
                return
            }
            let step = DockCalibration.next(measured: measured, target: calibration.target, tileSize: tileSize)
            if case let .adjust(adjusted) = step, round < DockCalibration.maxRounds {
                apply([DockSettingsPlan.tileSizeChange(adjusted)])
                calibrate(calibration, tileSize: adjusted, round: round + 1, restartsFinder: false, completion: completion)
                return
            }
            UserDefaults.standard.set(tileSize, forKey: DockCalibration.storageKey(for: calibration.edge))
            completion(.on(thickness: measured))
        }
        restartOwners(includingFinder: restartsFinder)
    }

    private static func saveCurrentValues() -> Bool {
        let stored = UserDefaults.standard.dictionary(forKey: savedValuesKey) as? [String: String]
        var saved = stored ?? [:]
        for setting in DockSettingsPlan.saved where saved[setting.id] == nil {
            saved[setting.id] = currentValue(of: setting) ?? DockSettingsPlan.absent
        }
        if saved != stored {
            UserDefaults.standard.set(saved, forKey: savedValuesKey)
            UserDefaults.standard.synchronize()
        }
        return stored == nil
    }

    private static func apply(_ changes: [DockSettingChange]) {
        for change in changes {
            switch change {
            case let .write(setting, value):
                defaults(["write", setting.domain, setting.key, setting.kind.flag, value])
            case let .delete(setting):
                defaults(["delete", setting.domain, setting.key])
            }
        }
    }

    private static func currentValue(of setting: DockSetting) -> String? {
        let result = run("/usr/bin/defaults", ["read", setting.domain, setting.key])
        return result.status == 0 ? result.output : nil
    }

    @discardableResult
    private static func defaults(_ arguments: [String]) -> Int32 {
        run("/usr/bin/defaults", arguments).status
    }

    private static func restartOwners(includingFinder: Bool) {
        _ = run("/usr/bin/killall", ["Dock"])
        if includingFinder {
            _ = run("/usr/bin/killall", ["Finder"])
        }
    }

    private static func run(_ path: String, _ arguments: [String]) -> (status: Int32, output: String) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
        } catch {
            return (-1, "")
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        let output = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
        return (process.terminationStatus, output)
    }
}

private final class DockMeasurer {
    private static let timeout: TimeInterval = 5
    private static let settleDelay: TimeInterval = 0.5

    private let edge: DockEdge
    private var completion: ((CGFloat?) -> Void)?
    private var observer: NSObjectProtocol?
    private var timeoutTimer: Timer?
    private var settleTimer: Timer?

    init(edge: DockEdge, completion: @escaping (CGFloat?) -> Void) {
        self.edge = edge
        self.completion = completion
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            self?.screenChanged()
        }
        timeoutTimer = Timer.scheduledTimer(withTimeInterval: Self.timeout, repeats: false) { [weak self] _ in
            guard let self else { return }
            self.finish(with: self.measure())
        }
    }

    func cancel() {
        completion = nil
        stop()
    }

    private func screenChanged() {
        settleTimer?.invalidate()
        settleTimer = Timer.scheduledTimer(withTimeInterval: Self.settleDelay, repeats: false) { [weak self] _ in
            guard let self, let measured = self.measure() else { return }
            self.finish(with: measured)
        }
    }

    private func finish(with measured: CGFloat?) {
        let completion = completion
        cancel()
        completion?(measured)
    }

    private func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
        observer = nil
        timeoutTimer?.invalidate()
        settleTimer?.invalidate()
    }

    private func measure() -> CGFloat? {
        guard let screen = NSScreen.screens.first else { return nil }
        return DockCalibration.thickness(edge: edge, frame: screen.frame, visibleFrame: screen.visibleFrame)
    }
}
