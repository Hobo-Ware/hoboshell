import Foundation
import HoboshellCore

enum TaskbarPinStore {
    private static let pinsKey = "TaskbarPins"
    static let didChange = Notification.Name("HoboshellTaskbarPinsDidChange")

    private static let groupingKey = "TaskbarGrouping"

    static func loadPins() -> TaskbarPins {
        TaskbarPins(UserDefaults.standard.stringArray(forKey: pinsKey) ?? [])
    }

    static func save(_ pins: TaskbarPins) {
        UserDefaults.standard.set(pins.ids, forKey: pinsKey)
        NotificationCenter.default.post(name: didChange, object: nil)
    }

    static func loadGrouping() -> TaskbarGrouping {
        TaskbarGrouping(stored: UserDefaults.standard.string(forKey: groupingKey))
    }

    static func save(_ grouping: TaskbarGrouping) {
        UserDefaults.standard.set(grouping.rawValue, forKey: groupingKey)
    }
}
