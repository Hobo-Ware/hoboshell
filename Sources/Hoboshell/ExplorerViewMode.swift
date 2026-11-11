import Foundation

enum ExplorerViewMode: String {
    case details
    case icons

    private static let savedKey = "ExplorerViewMode"

    static var saved: ExplorerViewMode {
        UserDefaults.standard.string(forKey: savedKey).flatMap(ExplorerViewMode.init(rawValue:)) ?? .details
    }

    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.savedKey)
    }
}
