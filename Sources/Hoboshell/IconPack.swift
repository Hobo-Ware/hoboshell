import Foundation

enum IconPack: String, CaseIterable {
    case folder
    case suitcase
    case beanCan = "bean-can"
    case sack
    case crate

    static let didChange = Notification.Name("IconPackDidChange")
    private static let savedKey = "IconPack"

    static var current: IconPack {
        get { UserDefaults.standard.string(forKey: savedKey).flatMap(IconPack.init(rawValue:)) ?? .folder }
        set {
            guard newValue != current else { return }
            UserDefaults.standard.set(newValue.rawValue, forKey: savedKey)
            HoboIcon.forgetRenderedIcons()
            NotificationCenter.default.post(name: didChange, object: nil)
        }
    }

    var title: String {
        switch self {
        case .folder: return "Tin folder"
        case .suitcase: return "Roped suitcase"
        case .beanCan: return "Bean can"
        case .sack: return "Patched sack"
        case .crate: return "Broken crate"
        }
    }

    func svg(named name: String) -> String? {
        HoboIconData.svg["\(rawValue)/\(name)"] ?? HoboIconData.svg[name]
    }
}
