import Testing
@testable import HoboshellCore

@Suite struct QuickSettingsTextTests {
    @Test func wifiTurnedOffReadsOff() {
        #expect(QuickSettingsText.wifiLabel(isPoweredOn: false, isConnected: true, name: "Home") == "Off")
    }

    @Test func wifiOnWithoutALinkReadsNotConnected() {
        #expect(QuickSettingsText.wifiLabel(isPoweredOn: true, isConnected: false, name: nil) == "Not connected")
    }

    @Test func wifiConnectedShowsTheNetworkName() {
        #expect(QuickSettingsText.wifiLabel(isPoweredOn: true, isConnected: true, name: "Home") == "Home")
    }

    @Test func wifiConnectedWithoutAKnownNameReadsConnected() {
        #expect(QuickSettingsText.wifiLabel(isPoweredOn: true, isConnected: true, name: nil) == "Connected")
        #expect(QuickSettingsText.wifiLabel(isPoweredOn: true, isConnected: true, name: "") == "Connected")
    }

    @Test func switchAndAppearanceLabels() {
        #expect(QuickSettingsText.switchLabel(isOn: true) == "On")
        #expect(QuickSettingsText.switchLabel(isOn: false) == "Off")
        #expect(QuickSettingsText.appearanceLabel(isDark: true) == "Dark")
        #expect(QuickSettingsText.appearanceLabel(isDark: false) == "Light")
    }
}
