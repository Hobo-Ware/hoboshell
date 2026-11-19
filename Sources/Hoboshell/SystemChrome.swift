import AppKit
import HoboshellCore

enum SystemChrome {
    static let wantedDidChange = Notification.Name("SystemChromeWantedDidChange")

    private static let savedValuesKey = "SystemChromeSavedValues"
    private static let wantedKey = "HideSystemUI"

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

    static func engage(completion: @escaping (DockReservation) -> Void) {
        let edge = DockEdge.bottom
        let tileSize = UserDefaults.standard.object(forKey: DockCalibration.storageKey(for: edge)) as? Int
            ?? DockCalibration.startingTileSize(target: DockCalibration.targetThickness(for: edge))
        let isFirstEngage = saveCurrentValues()
        apply(DockSettingsPlan.changes(for: edge, tileSize: tileSize))
        restartOwners(includingFinder: isFirstEngage)
        completion(.off)
    }

    static func restore() {
        guard let saved = UserDefaults.standard.dictionary(forKey: savedValuesKey) as? [String: String] else { return }
        apply(DockSettingsPlan.restoreChanges(saved: saved))
        UserDefaults.standard.removeObject(forKey: savedValuesKey)
        UserDefaults.standard.synchronize()
        restartOwners(includingFinder: true)
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
