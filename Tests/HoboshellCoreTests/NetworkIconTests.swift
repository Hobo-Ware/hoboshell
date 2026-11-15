import Testing
@testable import HoboshellCore

@Suite struct NetworkIconTests {
    private let online = NetworkSummary(isOnline: true, link: .wifi)
    private let offline = NetworkSummary(isOnline: false, link: .other)

    private func icon(
        available: Bool = true,
        powered: Bool = true,
        joined: Bool = true,
        rssi: Int = -50,
        summary: NetworkSummary
    ) -> NetworkIcon {
        NetworkIcon.resolve(isWiFiAvailable: available, isWiFiPoweredOn: powered, isWiFiJoined: joined, rssi: rssi, summary: summary)
    }

    @Test(arguments: [(-40, 3), (-60, 3), (-61, 2), (-70, 2), (-71, 1), (-80, 1), (-81, 1), (-95, 1)])
    func signalStepsFollowTheBarCutOffsAndNeverDropBelowOneBar(rssi: Int, bars: Int) {
        #expect(icon(rssi: rssi, summary: online) == .wifi(bars: bars))
    }

    @Test func aJoinedNetworkWithARouteShowsStrength() {
        #expect(icon(summary: online).symbolNames == ["wifi"])
        #expect(icon(rssi: -75, summary: online).variableValue == 1.0 / 3.0)
    }

    @Test func poweredOnButNotJoinedShowsTheEmptySymbol() {
        let result = icon(joined: false, summary: offline)
        #expect(result == .wifiNotJoined)
        #expect(result.variableValue == 0)
    }

    @Test func wifiTurnedOffShowsTheSlashedSymbol() {
        #expect(icon(powered: false, summary: offline) == .wifiOff)
        #expect(icon(powered: false, summary: offline).symbolNames == ["wifi.slash"])
    }

    @Test func joinedWithoutARouteWarnsNoInternet() {
        let result = icon(summary: offline)
        #expect(result == .noInternet)
        #expect(result.tone == .warning)
        #expect(result.symbolNames == ["wifi.exclamationmark"])
    }

    @Test func aCableWinsOverWifiState() {
        let wired = NetworkSummary(isOnline: true, link: .wired)
        #expect(icon(summary: wired) == .wired)
        #expect(icon(powered: false, summary: wired) == .wired)
        #expect(icon(available: false, summary: wired) == .wired)
    }

    @Test func theCableSymbolFallsBackToTheGlobe() {
        #expect(NetworkIcon.wired.symbolNames == ["cable.connector", "network"])
    }

    @Test func anotherOnlineLinkShowsTheNetworkSymbolWhenWifiIsOffOrNotJoined() {
        let cellular = NetworkSummary(isOnline: true, link: .cellular)
        #expect(icon(powered: false, summary: cellular) == .otherLink)
        #expect(icon(joined: false, summary: cellular) == .otherLink)
    }

    @Test func aMacWithoutWifiShowsOfflineOrTheOtherLink() {
        #expect(icon(available: false, summary: offline) == .offline)
        #expect(icon(available: false, summary: NetworkSummary(isOnline: true, link: .other)) == .otherLink)
    }

    @Test func onlyNoInternetIsTinted() {
        let all: [NetworkIcon] = [.wifi(bars: 2), .wifiNotJoined, .wifiOff, .wired, .otherLink, .offline]
        #expect(all.allSatisfy { $0.tone == .normal })
    }

    @Test func tooltipsNameTheState() {
        #expect(NetworkIcon.wifi(bars: 3).tooltipText(name: "Home") == "Wi-Fi: Home")
        #expect(NetworkIcon.wifi(bars: 3).tooltipText(name: nil) == "Wi-Fi connected")
        #expect(NetworkIcon.wifi(bars: 3).tooltipText(name: "") == "Wi-Fi connected")
        #expect(NetworkIcon.wifiNotJoined.tooltipText(name: nil) == "Wi-Fi: not connected")
        #expect(NetworkIcon.wifiOff.tooltipText(name: nil) == "Wi-Fi: off")
        #expect(NetworkIcon.noInternet.tooltipText(name: nil) == "Wi-Fi: no internet")
        #expect(NetworkIcon.wired.tooltipText(name: nil) == "Wired network")
        #expect(NetworkIcon.otherLink.tooltipText(name: nil) == "Network connected")
        #expect(NetworkIcon.offline.tooltipText(name: nil) == "Offline")
    }
}
