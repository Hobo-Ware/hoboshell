import Foundation
import HoboshellCore

enum ExplorerSettings {
    private static let sortKey = "ExplorerSort"
    private static let showsHiddenKey = "ExplorerShowsHidden"

    static var sort: ExplorerSort {
        get { ExplorerSort(stored: UserDefaults.standard.string(forKey: sortKey)) }
        set { UserDefaults.standard.set(newValue.stored, forKey: sortKey) }
    }

    static var showsHidden: Bool {
        get { UserDefaults.standard.bool(forKey: showsHiddenKey) }
        set { UserDefaults.standard.set(newValue, forKey: showsHiddenKey) }
    }
}
