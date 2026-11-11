import Foundation
import HoboshellCore

enum TaskbarPinStore {
    private static let pinsKey = "TaskbarPins"
    private static let groupingKey = "TaskbarGrouping"

    static func loadPins() -> TaskbarPins {
        TaskbarPins(UserDefaults.standard.stringArray(forKey: pinsKey) ?? [])
    }

    static func save(_ pins: TaskbarPins) {
        UserDefaults.standard.set(pins.ids, forKey: pinsKey)
    }

    static func loadGrouping() -> TaskbarGrouping {
        TaskbarGrouping(stored: UserDefaults.standard.string(forKey: groupingKey))
    }

    static func save(_ grouping: TaskbarGrouping) {
        UserDefaults.standard.set(grouping.rawValue, forKey: groupingKey)
    }
}
