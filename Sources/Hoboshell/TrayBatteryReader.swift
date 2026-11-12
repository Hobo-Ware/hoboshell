import Foundation
import HoboshellCore
import IOKit.ps

enum TrayBatteryReader {
    static func read() -> BatteryDetails? {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else { return nil }
        for source in sources {
            guard let details = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
                  let current = details[kIOPSCurrentCapacityKey] as? Int,
                  let capacity = details[kIOPSMaxCapacityKey] as? Int,
                  capacity > 0 else { continue }
            let isCharging = details[kIOPSIsChargingKey] as? Bool ?? false
            let minutesKey = isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
            return BatteryDetails(
                status: BatteryStatus(percent: current * 100 / capacity, isCharging: isCharging),
                isOnACPower: details[kIOPSPowerSourceStateKey] as? String == kIOPSACPowerValue,
                isFullyCharged: details[kIOPSIsChargedKey] as? Bool ?? false,
                minutes: details[minutesKey] as? Int
            )
        }
        return nil
    }
}
