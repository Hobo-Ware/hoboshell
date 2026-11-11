import Foundation
import HoboshellCore

enum StartMenuPinStore {
    private static let key = "StartPins"

    static func load(isInstalled: (String) -> Bool) -> TaskbarPins {
        let stored = UserDefaults.standard.stringArray(forKey: key)
        let pins = StartPinSeed.pins(stored: stored, isInstalled: isInstalled)
        if stored == nil {
            save(pins)
        }
        return pins
    }

    static func save(_ pins: TaskbarPins) {
        UserDefaults.standard.set(pins.ids, forKey: key)
    }
}
