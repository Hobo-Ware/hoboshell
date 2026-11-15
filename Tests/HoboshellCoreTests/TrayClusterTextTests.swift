import Testing
@testable import HoboshellCore

@Suite struct TrayClusterTextTests {
    @Test func volumeReadsPercentOrMuted() {
        #expect(TrayClusterText.volume(level: 0.4, isMuted: false) == "Volume 40%")
        #expect(TrayClusterText.volume(level: 0.4, isMuted: true) == "Volume muted")
    }

    @Test func batteryMentionsCharging() {
        #expect(TrayClusterText.battery(BatteryStatus(percent: 82, isCharging: false)) == "Battery 82%")
        #expect(TrayClusterText.battery(BatteryStatus(percent: 82, isCharging: true)) == "Battery 82%, charging")
    }

    @Test func theTooltipJoinsEveryPartThatExists() {
        #expect(TrayClusterText.tooltip(network: "Wi-Fi: Home", volume: "Volume 40%", battery: "Battery 82%") == "Wi-Fi: Home, Volume 40%, Battery 82%")
    }

    @Test func aMacWithoutABatteryLeavesItOut() {
        #expect(TrayClusterText.tooltip(network: "Offline", volume: "Volume 40%", battery: nil) == "Offline, Volume 40%")
    }

    @Test func aMacWithoutAnOutputDeviceLeavesVolumeOut() {
        #expect(TrayClusterText.tooltip(network: "Offline", volume: nil, battery: nil) == "Offline")
    }
}
