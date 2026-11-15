import CoreLocation
import Foundation

final class TrayLocationAccess: NSObject, CLLocationManagerDelegate {
    static let shared = TrayLocationAccess()
    static let didChange = Notification.Name("HoboshellTrayLocationAccessDidChange")

    private lazy var manager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()

    var isGranted: Bool {
        manager.authorizationStatus == .authorizedAlways
    }

    func requestIfUndecided() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }

    func allow() -> Bool {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
            return false
        }
        TraySettings.open(TraySettings.location)
        return true
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
}
