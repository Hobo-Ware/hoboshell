import Testing
@testable import HoboshellCore

@Suite struct BatteryDetailsTests {
    private func details(
        charging: Bool = false, ac: Bool = false, full: Bool = false, minutes: Int? = nil, percent: Int = 80
    ) -> BatteryDetails {
        BatteryDetails(
            status: BatteryStatus(percent: percent, isCharging: charging),
            isOnACPower: ac, isFullyCharged: full, minutes: minutes
        )
    }

    @Test func onBatteryShowsTheTimeRemaining() {
        let battery = details(minutes: 125)
        #expect(battery.stateText == "On battery")
        #expect(battery.timeText == "2 h 5 min remaining")
    }

    @Test func chargingShowsTheTimeToFull() {
        let battery = details(charging: true, ac: true, minutes: 45)
        #expect(battery.stateText == "Charging")
        #expect(battery.timeText == "45 min until full")
    }

    @Test func aFullBatteryShowsNoTime() {
        let battery = details(ac: true, full: true, minutes: 30)
        #expect(battery.stateText == "Fully charged")
        #expect(battery.timeText == nil)
    }

    @Test func pluggedInWithoutChargingShowsNoTime() {
        let battery = details(ac: true, minutes: 30)
        #expect(battery.stateText == "Plugged in, not charging")
        #expect(battery.timeText == nil)
    }

    @Test func aTimeTheSystemHasNotReportedIsLeftOut() {
        #expect(details(minutes: nil).timeText == nil)
        #expect(details(minutes: -1).timeText == nil)
        #expect(details(minutes: 0).timeText == nil)
    }

    @Test func wholeHoursDropTheMinutes() {
        #expect(BatteryDetails.durationText(minutes: 120) == "2 h")
    }

    @Test func underAnHourShowsOnlyMinutes() {
        #expect(BatteryDetails.durationText(minutes: 7) == "7 min")
    }

    @Test func lowPowerModeTextNamesTheState() {
        #expect(BatteryDetails.lowPowerModeText(isOn: true) == "Low Power Mode: On")
        #expect(BatteryDetails.lowPowerModeText(isOn: false) == "Low Power Mode: Off")
    }
}
