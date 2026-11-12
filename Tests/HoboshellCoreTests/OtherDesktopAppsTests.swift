import Testing
@testable import HoboshellCore

@Suite struct OtherDesktopAppsTests {
    @Test func appThatLostItsWindowsOnADesktopSwitchIsElsewhere() {
        var apps = OtherDesktopApps()
        let before = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [7])
        apps.desktopChanged()
        let after = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [])
        #expect([before, after] == [false, true])
    }

    @Test func appThatClosedItsWindowWithoutASwitchIsNotElsewhere() {
        var apps = OtherDesktopApps()
        let open = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [7])
        let closed = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [])
        #expect([open, closed] == [false, false])
    }

    @Test func comingBackToTheAppsDesktopClearsIt() {
        var apps = OtherDesktopApps()
        _ = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [7])
        apps.desktopChanged()
        _ = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [])
        apps.desktopChanged()
        let back = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [7])
        let closedThere = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [])
        #expect([back, closedThere] == [false, false])
    }

    @Test func appSeenOnlyAfterTheSwitchIsNotElsewhere() {
        var apps = OtherDesktopApps()
        _ = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [3])
        apps.desktopChanged()
        let neverHadWindows = apps.hasWindowsElsewhere(7, appsWithWindowsHere: [])
        let hadWindows = apps.hasWindowsElsewhere(3, appsWithWindowsHere: [])
        #expect([neverHadWindows, hadWindows] == [false, true])
    }
}
