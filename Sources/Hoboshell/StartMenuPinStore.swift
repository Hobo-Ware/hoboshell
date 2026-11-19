import Foundation
import HoboshellCore

enum StartMenuPinStore {
    private static let key = "StartPins"
    private static let offeredKey = "StartPinsOffered"

    static func load(isInstalled: (String) -> Bool) -> TaskbarPins {
        let defaults = UserDefaults.standard
        let stored = defaults.stringArray(forKey: key)
        let offered = defaults.stringArray(forKey: offeredKey)
        let pins = StartPinSeed.pins(stored: stored, offered: offered, isInstalled: isInstalled)
        if offered != StartPinSeed.bundleIdentifiers {
            save(pins)
            defaults.set(StartPinSeed.bundleIdentifiers, forKey: offeredKey)
        }
        return pins
    }

    static func save(_ pins: TaskbarPins) {
        UserDefaults.standard.set(pins.ids, forKey: key)
    }
}
