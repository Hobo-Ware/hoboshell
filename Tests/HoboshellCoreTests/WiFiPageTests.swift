import Testing
@testable import HoboshellCore

@Suite struct WiFiPageTests {
    private func scan(_ name: String, _ rssi: Int, secured: Bool = true) -> WiFiScanResult {
        WiFiScanResult(name: name, rssi: rssi, isSecured: secured)
    }

    private func networks(_ page: WiFiPage) -> WiFiNetworksPage? {
        if case .networks(let result) = page { return result }
        return nil
    }

    private func page(
        connection: WiFiConnection,
        scanned: [WiFiScanResult] = [],
        isScanning: Bool = false,
        namesAllowed: Bool = true,
        isAvailable: Bool = true,
        rssi: Int = -50
    ) -> WiFiPage {
        WiFiPage.make(
            isAvailable: isAvailable, connection: connection, namesAllowed: namesAllowed,
            isScanning: isScanning, rssi: rssi, scanned: scanned
        )
    }

    @Test func aConnectedNetworkWithoutAKnownNameStillGetsACurrentRow() {
        let result = networks(page(connection: .connected(name: nil), scanned: [scan("Home", -40), scan("Cafe", -60)]))
        #expect(result?.current == WiFiCurrentNetwork(name: nil, bars: 3, isSecured: nil))
        #expect(result?.heading == .networksNearby)
        #expect(result?.others.map(\.name) == ["Home", "Cafe"])
    }

    @Test func theJoinedNetworkIsTheCurrentRowAndNotListedAgain() {
        let result = networks(page(connection: .connected(name: "Home"), scanned: [scan("Home", -40), scan("Cafe", -60)]))
        #expect(result?.current == WiFiCurrentNetwork(name: "Home", bars: 3, isSecured: true))
        #expect(result?.others.map(\.name) == ["Cafe"])
        #expect(result?.heading == .otherNetworks)
    }

    @Test func theCurrentRowSaysWhetherTheNetworkIsSecured() {
        let secured = WiFiCurrentNetwork(name: "A", bars: 2, isSecured: true)
        let open = WiFiCurrentNetwork(name: "A", bars: 2, isSecured: false)
        let unknown = WiFiCurrentNetwork(name: "A", bars: 2, isSecured: nil)
        #expect([secured, open, unknown].map(\.statusText) == ["Connected, secured", "Connected, open", "Connected"])
    }

    @Test func aJoinedNetworkMissingFromTheScanHasNoLockInfo() {
        let result = networks(page(connection: .connected(name: "Home"), scanned: []))
        #expect(result?.current?.isSecured == nil)
    }

    @Test func notConnectedHasNoCurrentRowAndListsEverything() {
        let result = networks(page(connection: .notConnected, scanned: [scan("Home", -40)]))
        #expect(result?.current == nil)
        #expect(result?.others.map(\.name) == ["Home"])
        #expect(result?.heading == .networksNearby)
    }

    @Test func scanningWithNothingListedShowsTheLookingRow() {
        #expect(networks(page(connection: .notConnected, isScanning: true))?.progress == .scanning)
    }

    @Test func aFinishedScanWithNothingSaysNothingWasFound() {
        #expect(networks(page(connection: .notConnected))?.progress == .nothingFound)
    }

    @Test func aListedNetworkWinsOverTheScanningFlag() {
        #expect(networks(page(connection: .notConnected, scanned: [scan("Home", -40)], isScanning: true))?.progress == .listed)
    }

    @Test func wifiTurnedOffShowsTheOffScreen() {
        #expect(page(connection: .off, scanned: [scan("Home", -40)]) == .off)
    }

    @Test func aMacWithoutWifiShowsTheUnavailableScreen() {
        #expect(page(connection: .off, isAvailable: false) == .unavailable)
    }

    @Test func hiddenNamesShowThePermissionScreen() {
        #expect(page(connection: .connected(name: nil), scanned: [scan("Home", -40)], namesAllowed: false) == .namesHidden(isConnected: true))
        #expect(page(connection: .notConnected, namesAllowed: false) == .namesHidden(isConnected: false))
    }

    @Test func theCurrentRowSignalFollowsTheLinkStrength() {
        let weak = networks(page(connection: .connected(name: "Home"), rssi: -75))
        #expect(weak?.current?.bars == 1)
    }

    @Test func connectionNeedsPowerThenAnSsidOrALink() {
        #expect(WiFiConnection.resolve(isPoweredOn: false, ssid: "Home", hasLink: true) == .off)
        #expect(WiFiConnection.resolve(isPoweredOn: true, ssid: nil, hasLink: false) == .notConnected)
        #expect(WiFiConnection.resolve(isPoweredOn: true, ssid: "Home", hasLink: false) == .connected(name: "Home"))
        #expect(WiFiConnection.resolve(isPoweredOn: true, ssid: nil, hasLink: true) == .connected(name: nil))
    }

    @Test func headingsReadAsTheyAreShown() {
        #expect(WiFiNetworksPage.Heading.otherNetworks.title == "Other networks")
        #expect(WiFiNetworksPage.Heading.networksNearby.title == "Networks nearby")
    }

    @Test func anEmptyNameCountsAsUnknown() {
        #expect(WiFiConnection.connected(name: "").name == nil)
    }
}
