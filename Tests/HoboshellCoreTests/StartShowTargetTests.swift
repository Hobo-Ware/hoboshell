import Testing
@testable import HoboshellCore

@Suite struct StartShowTargetTests {
    @Test func startAllOpensTheAllAppsView() {
        #expect(ShowTarget.parse(arguments: ["--show", "start=all"]) == [.startAll])
    }

    @Test func startSearchCarriesTheText() {
        #expect(ShowTarget.parse(arguments: ["--show", "start=search:note pad"]) == [.startSearch(text: "note pad")])
    }

    @Test func startSearchWithoutTextIsIgnored() {
        #expect(ShowTarget.parse(arguments: ["--show", "start=search:"]).isEmpty)
    }

    @Test func anUnknownStartValueIsIgnored() {
        #expect(ShowTarget.parse(arguments: ["--show=start=wat"]).isEmpty)
    }

    @Test func startTargetsCombineWithOthers() {
        #expect(ShowTarget.parse(arguments: ["--show", "start=all", "--show=files"]) == [.startAll, .files(path: nil)])
    }

    @Test func switcherOpensTheWindowSwitcher() {
        #expect(ShowTarget.parse(arguments: ["--show", "switcher"]) == [.switcher])
    }

    @Test func switcherCombinesWithOtherTargets() {
        #expect(ShowTarget.parse(arguments: ["--show=switcher", "--show", "start"]) == [.switcher, .start])
    }

    @Test func switcherWithAValueIsIgnored() {
        #expect(ShowTarget.parse(arguments: ["--show=switcher=all"]).isEmpty)
    }
}

@Suite struct TrayShowTargetTests {
    @Test func trayNetworkOpensTheQuickSettingsPanel() {
        #expect(ShowTarget.parse(arguments: ["--show", "tray=network"]) == [.tray(.network)])
    }

    @Test func trayWifiOpensTheWifiPage() {
        #expect(ShowTarget.parse(arguments: ["--show=tray=wifi"]) == [.tray(.wifi)])
    }

    @Test func theWifiPageAnchorsToTheNetworkItem() {
        #expect(TrayItemKind.wifi.anchorKind == .network)
        #expect(TrayItemKind.volume.anchorKind == .volume)
    }

    @Test func anUnknownTrayItemIsIgnored() {
        #expect(ShowTarget.parse(arguments: ["--show", "tray=bluetooth"]).isEmpty)
    }
}
