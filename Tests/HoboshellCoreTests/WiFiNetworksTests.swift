import Testing
@testable import HoboshellCore

@Suite struct WiFiNetworksTests {
    private func scan(_ name: String, _ rssi: Int, secured: Bool = true) -> WiFiScanResult {
        WiFiScanResult(name: name, rssi: rssi, isSecured: secured)
    }

    @Test func strongestNetworkComesFirst() {
        let names = WiFiNetworks.others(from: [scan("Far", -80), scan("Near", -40), scan("Mid", -60)], excluding: nil).map(\.name)
        #expect(names == ["Near", "Mid", "Far"])
    }

    @Test func accessPointsWithTheSameNameMergeIntoTheStrongest() {
        let merged = WiFiNetworks.others(from: [scan("Home", -75, secured: false), scan("Home", -45, secured: true)], excluding: nil)
        #expect(merged == [WiFiNetwork(name: "Home", rssi: -45, isSecured: true)])
    }

    @Test func theCurrentNetworkIsLeftOut() {
        #expect(WiFiNetworks.others(from: [scan("Home", -40), scan("Cafe", -60)], excluding: "Home").map(\.name) == ["Cafe"])
    }

    @Test func hiddenNetworksWithoutAnAvailableNameAreDropped() {
        #expect(WiFiNetworks.others(from: [scan("", -40), scan("Cafe", -60)], excluding: nil).map(\.name) == ["Cafe"])
    }

    @Test func equalSignalFallsBackToNameOrder() {
        #expect(WiFiNetworks.others(from: [scan("beta", -50), scan("Alpha", -50)], excluding: nil).map(\.name) == ["Alpha", "beta"])
    }

    @Test func theListIsCappedAtTheLimit() {
        let many = (0..<20).map { scan("Net \($0)", -40 - $0) }
        #expect(WiFiNetworks.others(from: many, excluding: nil).count == WiFiNetworks.maxShown)
        #expect(WiFiNetworks.others(from: many, excluding: nil, limit: 3).map(\.name) == ["Net 0", "Net 1", "Net 2"])
    }

    @Test func noScanResultsGiveAnEmptyList() {
        #expect(WiFiNetworks.others(from: [], excluding: "Home").isEmpty)
    }

    @Test func signalStrengthMapsToBars() {
        #expect([-30, -60, -61, -70, -71, -80, -81, -95].map { WiFiSignal.bars(rssi: $0) } == [3, 3, 2, 2, 1, 1, 0, 0])
    }

    @Test func aNetworkReportsBarsFromItsSignal() {
        #expect(WiFiNetwork(name: "A", rssi: -65, isSecured: false).bars == 2)
    }
}
