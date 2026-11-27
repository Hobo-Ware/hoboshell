import Foundation
import HoboshellCore

enum TaskbarPinStore {
    private static let pinsKey = "TaskbarPins"
    static let didChange = Notification.Name("HoboshellTaskbarPinsDidChange")

    private static let groupingKey = "TaskbarGrouping"
    private static let alignmentKey = "TaskbarAlignment"
    private static let showsDownloadsKey = "TaskbarShowsDownloads"

    static func loadPins() -> TaskbarPins {
        TaskbarPins(UserDefaults.standard.stringArray(forKey: pinsKey) ?? [])
    }

    static func save(_ pins: TaskbarPins) {
        UserDefaults.standard.set(pins.ids, forKey: pinsKey)
        NotificationCenter.default.post(name: didChange, object: nil)
    }

    static func loadGrouping() -> TaskbarGrouping {
        guard SelfTestArguments.parse(CommandLine.arguments) == nil else { return .never }
        return TaskbarGrouping(stored: UserDefaults.standard.string(forKey: groupingKey))
    }

    static func save(_ grouping: TaskbarGrouping) {
        UserDefaults.standard.set(grouping.rawValue, forKey: groupingKey)
    }

    static func loadAlignment() -> TaskbarAlignment {
        TaskbarAlignment(stored: UserDefaults.standard.string(forKey: alignmentKey))
    }

    static func save(_ alignment: TaskbarAlignment) {
        UserDefaults.standard.set(alignment.rawValue, forKey: alignmentKey)
    }

    static func loadShowsDownloads() -> Bool {
        UserDefaults.standard.bool(forKey: showsDownloadsKey)
    }

    static func save(showsDownloads: Bool) {
        UserDefaults.standard.set(showsDownloads, forKey: showsDownloadsKey)
    }
}
