import Testing
@testable import HoboshellCore

@Suite struct NetworkSummaryTests {
    @Test func anOnlineWifiLinkReadsConnectedWithWifi() {
        let summary = NetworkSummary(isOnline: true, link: .wifi)
        #expect(summary.statusText == "Connected")
        #expect(summary.kindText == "Wi-Fi")
        #expect(summary.symbolName == "wifi")
    }

    @Test func anOnlineWiredLinkReadsWired() {
        let summary = NetworkSummary(isOnline: true, link: .wired)
        #expect(summary.kindText == "Wired")
        #expect(summary.symbolName == "network")
    }

    @Test func offlineHidesTheKindAndCrossesTheSymbol() {
        let summary = NetworkSummary(isOnline: false, link: .wifi)
        #expect(summary.statusText == "Offline")
        #expect(summary.kindText == nil)
        #expect(summary.symbolName == "wifi.slash")
    }

    @Test func thePreferredInterfaceWinsTheAddress() {
        let candidates = [
            NetworkAddress.Candidate(interface: "en1", address: "10.0.0.7"),
            NetworkAddress.Candidate(interface: "en0", address: "192.168.1.20"),
        ]
        #expect(NetworkAddress.pick(from: candidates, preferring: ["en0"]) == "192.168.1.20")
    }

    @Test func withoutAPreferredMatchTheFirstUsableAddressWins() {
        let candidates = [NetworkAddress.Candidate(interface: "utun2", address: "100.64.0.3")]
        #expect(NetworkAddress.pick(from: candidates, preferring: ["en0"]) == "100.64.0.3")
    }

    @Test func loopbackAndLinkLocalAddressesAreIgnored() {
        let candidates = [
            NetworkAddress.Candidate(interface: "lo0", address: "127.0.0.1"),
            NetworkAddress.Candidate(interface: "en0", address: "169.254.10.2"),
        ]
        #expect(NetworkAddress.pick(from: candidates, preferring: ["en0"]) == nil)
    }

    @Test func noCandidatesGiveNoAddress() {
        #expect(NetworkAddress.pick(from: [], preferring: ["en0"]) == nil)
    }
}
