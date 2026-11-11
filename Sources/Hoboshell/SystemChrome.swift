import Foundation

enum SystemChrome {
    private struct Setting {
        let domain: String
        let key: String
        let type: String
        let hiddenValue: String

        var id: String { "\(domain)/\(key)" }
    }

    private static let settings = [
        Setting(domain: "com.apple.dock", key: "autohide", type: "-bool", hiddenValue: "true"),
        Setting(domain: "com.apple.dock", key: "autohide-delay", type: "-float", hiddenValue: "1000"),
        Setting(domain: "com.apple.finder", key: "CreateDesktop", type: "-bool", hiddenValue: "false"),
    ]
    private static let savedValuesKey = "SystemChromeSavedValues"
    private static let absent = ""

    static func hide() {
        if UserDefaults.standard.dictionary(forKey: savedValuesKey) == nil {
            var saved: [String: String] = [:]
            for setting in settings {
                saved[setting.id] = currentValue(of: setting) ?? absent
            }
            UserDefaults.standard.set(saved, forKey: savedValuesKey)
            UserDefaults.standard.synchronize()
        }
        for setting in settings {
            defaults(["write", setting.domain, setting.key, setting.type, setting.hiddenValue])
        }
        restartOwners()
    }

    static func restore() {
        guard let saved = UserDefaults.standard.dictionary(forKey: savedValuesKey) as? [String: String] else { return }
        for setting in settings {
            let previous = saved[setting.id] ?? absent
            if previous == absent {
                defaults(["delete", setting.domain, setting.key])
            } else {
                defaults(["write", setting.domain, setting.key, setting.type, previous])
            }
        }
        UserDefaults.standard.removeObject(forKey: savedValuesKey)
        UserDefaults.standard.synchronize()
        restartOwners()
    }

    private static func currentValue(of setting: Setting) -> String? {
        let result = run("/usr/bin/defaults", ["read", setting.domain, setting.key])
        return result.status == 0 ? result.output : nil
    }

    @discardableResult
    private static func defaults(_ arguments: [String]) -> Int32 {
        run("/usr/bin/defaults", arguments).status
    }

    private static func restartOwners() {
        _ = run("/usr/bin/killall", ["Dock"])
        _ = run("/usr/bin/killall", ["Finder"])
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
